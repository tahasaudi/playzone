from __future__ import annotations
import argparse, time, threading, os, re
import cv2, numpy as np
from core.config import load_config, resolve_path
from core.detector import FridgeDetector
from main import open_camera

os.environ["OPENCV_FFMPEG_CAPTURE_OPTIONS"] = "rtsp_transport;tcp|stimeout;400000|max_delay;0|buffer_size;1024"
os.environ["OPENCV_LOG_LEVEL"] = "SILENT"
os.environ["OMP_NUM_THREADS"] = "3"
os.environ["MKL_NUM_THREADS"] = "3"

class Cam:
    def __init__(self, cam, det):
        self.name = cam["name"]
        src = cam["source"]
        src2 = re.sub(r"/Streaming/channels/(\d)01$", r"/Streaming/channels/\g<1>02", src)
        if src2 == src: src2 = re.sub(r"/channels/(\d)01$", r"/channels/\g<1>02", src)
        self.src = src2
        self.det = det
        self.cap = None
        self.f = None
        self.lock = threading.Lock()
        self.stop = False
        self.last_det = 0
        self.boxes = []
    def start(self):
        threading.Thread(target=self.run, daemon=True).start()
        threading.Thread(target=self.det_loop, daemon=True).start()
    def run(self):
        while not self.stop:
            if self.cap is None or not self.cap.isOpened():
                try:
                    self.cap = open_camera(self.src)
                    try: self.cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)
                    except: pass
                    for _ in range(4):
                        try: self.cap.grab()
                        except: break
                except:
                    time.sleep(0.15); continue
                time.sleep(0.05); continue
            try:
                for _ in range(3):
                    if not self.cap.grab(): break
                ok, fr = self.cap.retrieve()
            except:
                try: self.cap.release()
                except: pass
                self.cap = None
                time.sleep(0.1); continue
            if not ok or fr is None:
                time.sleep(0.001); continue
            with self.lock:
                self.f = fr.copy()
    def det_loop(self):
        while not self.stop:
            with self.lock:
                fr = self.f.copy() if self.f is not None else None
            if fr is None:
                time.sleep(0.005); continue
            now = time.time()
            if now - self.last_det < 0.12:
                time.sleep(0.005); continue
            try:
                d = self.det.detect(fr)
                self.boxes = d
                self.last_det = now
            except:
                time.sleep(0.03); continue

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--shop", action="store_true")
    ap.add_argument("--config")
    args = ap.parse_args()
    cfg = load_config(args.config)
    det = FridgeDetector(weights=resolve_path("yolo11n.pt", cfg["_base_dir"]), conf_thres=0.18, iou_thres=0.5, keep_labels=[], imgsz=224)
    cams = [Cam(c,det) for c in cfg["shop"]["cameras"]]
    for c in cams: c.start()
    win = "PlayZone - Shop Cameras"
    cv2.namedWindow(win, cv2.WINDOW_NORMAL)
    cv2.resizeWindow(win, 1000, 560)
    try:
        cv2.setWindowProperty(win, cv2.WND_PROP_TOPMOST, 1)
        cv2.setWindowProperty(win, cv2.WND_PROP_TOPMOST, 0)
    except: pass
    cols=4; tw,th=250,140
    while True:
        tiles=[]
        on=0
        for c in cams:
            with c.lock:
                f = c.f.copy() if c.f is not None else None
            boxes = c.boxes
            if f is None:
                t=np.zeros((th,tw,3),dtype=np.uint8)
                cv2.putText(t,c.name,(4,12),cv2.FONT_HERSHEY_SIMPLEX,0.28,(160,160,160),1)
                tiles.append(t)
            else:
                v = f.copy()
                for it in boxes:
                    x1,y1,x2,y2 = it["bbox"]
                    cv2.rectangle(v,(x1,y1),(x2,y2),(0,255,0),1)
                    cv2.putText(v,it["label"],(x1,max(12,y1-2)),cv2.FONT_HERSHEY_SIMPLEX,0.32,(0,255,0),1)
                h,w=v.shape[:2]; sc=min(tw/w,th/h)
                r=cv2.resize(v,(int(w*sc),int(h*sc)))
                cn=np.zeros((th,tw,3),dtype=np.uint8)
                y=(th-r.shape[0])//2;x=(tw-r.shape[1])//2
                cn[y:y+r.shape[0],x:x+r.shape[1]]=r
                tiles.append(cn); on+=1
        while len(tiles)%cols: tiles.append(np.zeros((th,tw,3),dtype=np.uint8))
        rows=[np.hstack(tiles[i:i+cols]) for i in range(0,len(tiles),cols)]
        grid=np.vstack(rows)
        cv2.putText(grid,f"{on}/{len(cams)} LIVE + AI", (6,grid.shape[0]-5),cv2.FONT_HERSHEY_SIMPLEX,0.4,(0,255,0),1)
        cv2.imshow(win,grid)
        if cv2.waitKey(1)&0xFF in (ord('q'),27): break
        try:
            if cv2.getWindowProperty(win,cv2.WND_PROP_VISIBLE)<1: break
        except: break
    for c in cams: c.stop=True
    cv2.destroyAllWindows()

if __name__=="__main__":
    main()
