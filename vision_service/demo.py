from __future__ import annotations
import argparse, time, threading, os, re
import cv2, numpy as np
from core.config import load_config, resolve_path
from core.detector import FridgeDetector
from main import open_camera

os.environ["OPENCV_FFMPEG_CAPTURE_OPTIONS"] = "rtsp_transport;tcp|stimeout;800000|max_delay;0|buffer_size;2048"
os.environ["OMP_NUM_THREADS"] = "4"
os.environ["MKL_NUM_THREADS"] = "4"

class Cam:
    def __init__(self, cam, det):
        self.name = cam["name"]
        src = cam["source"]
        src2 = re.sub(r"/Streaming/channels/(\d)01$", r"/Streaming/channels/\g<1>02", src)
        if src2 == src:
            src2 = re.sub(r"/channels/(\d)01$", r"/channels/\g<1>02", src)
        self.src = src2
        self.det = det
        self.cap = None
        self.f = None
        self.lock = threading.Lock()
        self.stop = False
        self.last = time.time()
        self.fps = 0
        self.det_frame = None
    def start(self):
        threading.Thread(target=self.run, daemon=True).start()
    def run(self):
        while not self.stop:
            if self.cap is None or not self.cap.isOpened():
                try:
                    self.cap = open_camera(self.src)
                    try: self.cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)
                    except: pass
                except:
                    time.sleep(0.25); continue
                time.sleep(0.1); continue
            try:
                self.cap.grab()
                ok, fr = self.cap.retrieve()
            except:
                try: self.cap.release()
                except: pass
                self.cap = None
                time.sleep(0.2); continue
            if not ok or fr is None:
                time.sleep(0.005); continue
            now = time.time()
            if now-self.last>0: self.fps = self.fps*0.7 + (1.0/(now-self.last))*0.3
            self.last = now
            vis = fr.copy()
            try:
                dets = self.det.detect(fr)
                for it in dets:
                    x1,y1,x2,y2 = it["bbox"]
                    cv2.rectangle(vis,(x1,y1),(x2,y2),(0,255,0),2)
                    cv2.putText(vis,it["label"],(x1,max(14,y1-3)),cv2.FONT_HERSHEY_SIMPLEX,0.38,(0,255,0),1,cv2.LINE_AA)
            except Exception:
                pass
            with self.lock:
                self.f = vis

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--shop", action="store_true")
    ap.add_argument("--config")
    ap.add_argument("--no-window", action="store_true")
    ap.add_argument("--conf", type=float)
    ap.add_argument("--imgsz", type=int)
    args = ap.parse_args()
    cfg = load_config(args.config)
    det = FridgeDetector(
        weights=resolve_path(cfg["model"]["weights"], cfg["_base_dir"]),
        conf_thres=args.conf if args.conf is not None else 0.25,
        iou_thres=0.45,
        keep_labels=[],
        imgsz=args.imgsz or 320,
    )
    cams = [Cam(c, det) for c in cfg["shop"]["cameras"]]
    for c in cams: c.start()
    win = "PlayZone - Shop Cameras"
    cv2.namedWindow(win, cv2.WINDOW_NORMAL)
    cv2.resizeWindow(win, 1100, 620)
    try:
        cv2.setWindowProperty(win, cv2.WND_PROP_TOPMOST, 1)
        cv2.setWindowProperty(win, cv2.WND_PROP_TOPMOST, 0)
    except: pass
    cols = 4
    tw, th = 275, 155
    while True:
        tiles=[]
        on=0
        for c in cams:
            with c.lock: f=c.f
            if f is None:
                t=np.zeros((th,tw,3),dtype=np.uint8)
                cv2.putText(t,c.name,(6,16),cv2.FONT_HERSHEY_SIMPLEX,0.32,(200,200,200),1)
                cv2.putText(t,"...",(6,36),cv2.FONT_HERSHEY_SIMPLEX,0.28,(120,120,120),1)
                tiles.append(t)
            else:
                h,w=f.shape[:2]; sc=min(tw/w,th/h)
                r=cv2.resize(f,(int(w*sc),int(h*sc)))
                cn=np.zeros((th,tw,3),dtype=np.uint8)
                y=(th-r.shape[0])//2;x=(tw-r.shape[1])//2
                cn[y:y+r.shape[0],x:x+r.shape[1]]=r
                cv2.rectangle(cn,(0,0),(tw-1,th-1),(40,40,40),1)
                cv2.putText(cn,f"{c.name}",(4,12),cv2.FONT_HERSHEY_SIMPLEX,0.3,(0,255,0),1)
                tiles.append(cn); on+=1
        while len(tiles)%cols: tiles.append(np.zeros((th,tw,3),dtype=np.uint8))
        rows=[np.hstack(tiles[i:i+cols]) for i in range(0,len(tiles),cols)]
        grid=np.vstack(rows)
        cv2.putText(grid,f"{on}/{len(cams)} LIVE + AI", (6,grid.shape[0]-5),cv2.FONT_HERSHEY_SIMPLEX,0.4,(0,255,0),1)
        cv2.imshow(win,grid)
        k=cv2.waitKey(1)&0xFF
        if k in (ord("q"),27): break
        try:
            if cv2.getWindowProperty(win,cv2.WND_PROP_VISIBLE)<1: break
        except: break
    for c in cams: c.stop=True
    cv2.destroyAllWindows()

if __name__=="__main__":
    main()
