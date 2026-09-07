"""Configure existing DragonHaven projects with the owner's Firebase CLI login.

Never attaches billing, enables Analytics, creates databases or deploys Firebase
Functions. Credential material stays in ignored .tools storage; output contains
only public project/app identifiers and fixed operational status.
"""
import argparse
import base64
import json
import pathlib
import re
import time
import urllib.error
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parent.parent
HOSTS = {"firebase.googleapis.com", "cloudresourcemanager.googleapis.com",
         "cloudbilling.googleapis.com", "serviceusage.googleapis.com", "iam.googleapis.com"}


class SetupError(Exception):
    pass


def request(host, path, method="GET", body=None, missing_ok=False):
    if host not in HOSTS or not path.startswith("/"):
        raise SetupError("setup_endpoint_invalid")
    config = pathlib.Path.home() / ".config/configstore/firebase-tools.json"
    token = json.loads(config.read_text(encoding="utf-8")).get("tokens", {}).get("access_token")
    if not token:
        raise SetupError("firebase_cli_login_required")
    data = None if body is None else json.dumps(body).encode()
    req = urllib.request.Request("https://" + host + path, data=data, method=method,
                                 headers={"Authorization": "Bearer " + token,
                                          "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=30) as response:
            return json.load(response)
    except urllib.error.HTTPError as error:
        if missing_ok and error.code == 404:
            return None
        # Do not include provider response bodies, OAuth tokens or key material.
        raise SetupError(f"google_api_{host}_{method.lower()}_{error.code}") from None


def operation(host, name, version="v1beta1"):
    for _ in range(40):
        result = request(host, f"/{version}/{name}")
        if result.get("done"):
            if "error" in result:
                raise SetupError("google_operation_failed_" + str(result["error"].get("code", "unknown")))
            return result.get("response", {})
        time.sleep(2)
    raise SetupError("google_operation_timeout")


def require_free(project):
    billing = request("cloudbilling.googleapis.com", f"/v1/projects/{project}/billingInfo")
    if billing.get("billingEnabled") or billing.get("billingAccountName"):
        raise SetupError("project_has_billing_manual_review_required")


def configure(project, environment):
    if not re.fullmatch(r"dragonhaven-[a-z0-9-]{3,24}", project):
        raise SetupError("dragonhaven_project_id_required")
    require_free(project)
    firebase = request("firebase.googleapis.com", f"/v1beta1/projects/{project}", missing_ok=True)
    if firebase is None:
        pending = request("firebase.googleapis.com", f"/v1beta1/projects/{project}:addFirebase", "POST", {})
        firebase = operation("firebase.googleapis.com", pending["name"])
    number = firebase["projectNumber"]
    # These existing Firebase product APIs do not require a billing account.
    enabled = request("serviceusage.googleapis.com", f"/v1/projects/{number}/services:batchEnable", "POST", {
        "serviceIds": ["fcm.googleapis.com", "firebasecrashlytics.googleapis.com",
                       "firebaseinstallations.googleapis.com", "firebaseremoteconfig.googleapis.com",
                       "iam.googleapis.com"]})
    operation("serviceusage.googleapis.com", enabled["name"], "v1")
    apps = request("firebase.googleapis.com", f"/v1beta1/projects/{project}/androidApps").get("apps", [])
    app = next((x for x in apps if x.get("packageName") == "nl.dragonhaven.app"), None)
    if app is None:
        pending = request("firebase.googleapis.com", f"/v1beta1/projects/{project}/androidApps", "POST", {
            "displayName": "DragonHaven " + environment, "packageName": "nl.dragonhaven.app"})
        app = operation("firebase.googleapis.com", pending["name"])
    config = request("firebase.googleapis.com", f'/v1beta1/{app["name"]}/config')
    directory = ROOT / ".tools/firebase-secrets" / environment
    directory.mkdir(parents=True, exist_ok=True)
    (directory / "google-services.json").write_bytes(base64.b64decode(config["configFileContents"]))
    print(json.dumps({"project_id": project, "environment": environment,
                      "app_id": app["appId"], "billing_enabled": False,
                      "config_saved": True}), flush=True)
    email = "dragonhaven-fcm@" + project + ".iam.gserviceaccount.com"
    name = f"projects/{project}/serviceAccounts/{email}"
    account = request("iam.googleapis.com", "/v1/" + name, missing_ok=True)
    if account is None:
        account = request("iam.googleapis.com", f"/v1/projects/{project}/serviceAccounts", "POST", {
            "accountId": "dragonhaven-fcm", "serviceAccount": {"displayName": "DragonHaven FCM sender"}})
    role = f"projects/{project}/roles/dragonhavenFcmSender"
    custom_role = request("iam.googleapis.com", "/v1/" + role, missing_ok=True)
    if custom_role is None:
        request("iam.googleapis.com", f"/v1/projects/{project}/roles", "POST", {
            "roleId": "dragonhavenFcmSender", "role": {
                "title": "DragonHaven FCM sender", "stage": "GA",
                "includedPermissions": ["cloudmessaging.messages.create"]}})
    elif custom_role.get("includedPermissions") != ["cloudmessaging.messages.create"]:
        raise SetupError("sender_role_permissions_changed_review_required")
    policy = request("cloudresourcemanager.googleapis.com", f"/v1/projects/{project}:getIamPolicy", "POST", {})
    member = "serviceAccount:" + email
    # Remove this tool's former broader binding only for its own sender.
    for old_binding in policy.get("bindings", []):
        if old_binding.get("role") == "roles/firebasecloudmessaging.admin":
            old_binding["members"] = [x for x in old_binding["members"] if x != member]
    policy["bindings"] = [x for x in policy.get("bindings", []) if x.get("members")]
    binding = next((x for x in policy.get("bindings", []) if x.get("role") == role and "condition" not in x), None)
    if binding is None:
        binding = {"role": role, "members": []}
        policy.setdefault("bindings", []).append(binding)
    if member not in binding["members"]:
        binding["members"].append(member)
    # New service accounts can take a few seconds to propagate to IAM policy.
    for attempt in range(5):
        try:
            request("cloudresourcemanager.googleapis.com", f"/v1/projects/{project}:setIamPolicy", "POST", {"policy": policy})
            break
        except SetupError as error:
            if not str(error).endswith('_400') or attempt == 4:
                raise
            time.sleep(4)
    key_path = directory / "fcm-service-account.json"
    if key_path.exists():
        existing = json.loads(key_path.read_text())
        if existing.get("project_id") != project or existing.get("client_email") != email:
            raise SetupError("existing_service_key_owner_mismatch")
        keys = request("iam.googleapis.com", "/v1/" + name + "/keys?keyTypes=USER_MANAGED").get("keys", [])
        if not any(x["name"].endswith("/" + existing.get("private_key_id", "missing")) and not x.get("disabled") for x in keys):
            raise SetupError("existing_service_key_invalid_rotate_explicitly")
    else:
        key = request("iam.googleapis.com", "/v1/" + name + "/keys", "POST", {"privateKeyType": "TYPE_GOOGLE_CREDENTIALS_FILE"})
        key_path.write_bytes(base64.b64decode(key["privateKeyData"]))
        key_path.chmod(0o600)
    require_free(project)
    print(json.dumps({"project_id": project, "sender_configured": True,
                      "sender_role": role, "billing_enabled": False}), flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", required=True)
    parser.add_argument("--environment", choices=["production", "staging"], required=True)
    args = parser.parse_args()
    try:
        configure(args.project, args.environment)
    except (SetupError, OSError, ValueError, KeyError) as error:
        print(str(error) if isinstance(error, SetupError) else "firebase_setup_local_or_transport_error", flush=True)
        raise SystemExit(1)
