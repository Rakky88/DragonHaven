"""Local planning estimates, not a provider invoice or a capacity guarantee."""
import argparse
import json
import math


def estimate(accounts, dau_fraction=.3, peak_fraction=.1, save_kib=100,
             history=5, requests_per_dau=120, response_kib=2, days=30):
    values = (accounts, dau_fraction, peak_fraction, save_kib, history,
              requests_per_dau, response_kib, days)
    if any(not math.isfinite(x) or x < 0 for x in values) or days == 0:
        raise ValueError("Inputs must be finite and non-negative; days must be positive")
    if not 0 <= peak_fraction <= dau_fraction <= 1:
        raise ValueError("Peak fraction must not exceed DAU fraction, both at most one")
    dau = math.ceil(accounts * dau_fraction)
    storage = accounts * save_kib * 1024 * (history + 1)
    egress = dau * requests_per_dau * response_kib * 1024 * days
    return {"accounts": accounts, "estimated_dau": dau,
            "estimated_peak_ccu": math.ceil(accounts * peak_fraction),
            "save_payload_mib": round(storage / 1024**2, 2),
            "read_egress_gib_per_period": round(egress / 1024**3, 2),
            "exceeds_500_mib_save_payload": storage > 500 * 1024**2,
            "exceeds_5_gib_uncached_egress": egress > 5 * 1024**3,
            "omitted": "DB compression/overhead, inventory, ledgers, auth, writes, retries, backups and assets"}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--accounts", nargs="+", type=int, default=[100, 1000, 10000])
    parser.add_argument("--dau-fraction", type=float, default=.3)
    parser.add_argument("--peak-fraction", type=float, default=.1)
    parser.add_argument("--save-kib", type=float, default=100)
    parser.add_argument("--history", type=int, default=5)
    parser.add_argument("--requests-per-dau", type=int, default=120)
    parser.add_argument("--response-kib", type=float, default=2)
    parser.add_argument("--days", type=int, default=30)
    args = vars(parser.parse_args())
    accounts = args.pop("accounts")
    try:
        print(json.dumps([estimate(value, **args) for value in accounts], indent=2))
    except ValueError as error:
        parser.error(str(error))
