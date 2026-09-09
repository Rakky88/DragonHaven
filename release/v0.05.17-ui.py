import subprocess,sys,xml.etree.ElementTree as ET
from pathlib import Path
adb='C:/Users/groot/AppData/Local/Android/Sdk/platform-tools/adb.exe'
def call(*args):
 r=subprocess.run([adb,'-s','emulator-5554',*args],capture_output=True,text=True)
 if r.returncode: raise RuntimeError(r.stderr)
 return r.stdout
mode=sys.argv[1]
if mode=='tap': print(call('shell','input','tap',*sys.argv[2:4]))
elif mode=='swipe': print(call('shell','input','swipe',*sys.argv[2:]))
elif mode=='back': print(call('shell','input','keyevent','4'))
elif mode=='capture':
 name='v0.05.17-'+sys.argv[2]
 call('shell','screencap','-p','/sdcard/release-check.png')
 call('pull','/sdcard/release-check.png','release/'+name+'.png')
 call('shell','uiautomator','dump','/sdcard/release-check.xml')
 call('pull','/sdcard/release-check.xml','release/'+name+'.xml')
 for n in ET.parse('release/'+name+'.xml').iter('node'):
  t=n.attrib.get('text') or n.attrib.get('content-desc')
  if t: print(t.encode('ascii','backslashreplace').decode(),n.attrib['bounds'], 'selected='+n.attrib.get('selected',''))
