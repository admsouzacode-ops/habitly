from PIL import Image, ImageDraw
import math
GREEN=(27,122,75,255); WHITE=(255,255,255,255)
S=4
def raw_mark(W, color):
    img=Image.new('L',(W,W),0); d=ImageDraw.Draw(img)
    P=lambda x,y:(x*W,y*W)
    w=int(W*0.12)
    a,b,c=(0.10,0.58),(0.36,0.82),(0.66,0.42)
    d.line([P(*a),P(*b),P(*c)],fill=255,width=w,joint='curve')
    for p in (a,c):
        x,y=P(*p); r=w/2; d.ellipse([x-r,y-r,x+r,y+r],fill=255)
    # leaf sprouting from check end, pointing up-right
    L=0.34; ang=math.radians(-40)
    ux,uy=math.cos(ang),math.sin(ang)
    base=(c[0]+ux*0.02, c[1]+uy*0.02)
    pts=[]
    N=60
    for i in range(N+1):
        t=i/N; pts.append((t*L, math.sin(math.pi*t)*L*0.30))
    for i in range(N,-1,-1):
        t=i/N; pts.append((t*L, -math.sin(math.pi*t)*L*0.30))
    poly=[P(base[0]+x*ux-y*uy, base[1]+x*uy+y*ux) for x,y in pts]
    d.polygon(poly,fill=255)
    # vein
    d.line([P(base[0]+0.05*ux,base[1]+0.05*uy),P(base[0]+0.27*ux,base[1]+0.27*uy)],fill=0,width=max(2,int(W*0.018)))
    return img
def mark(canvas, scale, bg=None):
    W=canvas*S
    m=raw_mark(2000,255)
    bbox=m.getbbox(); m=m.crop(bbox)
    side=int(W*scale); k=side/max(m.size)
    m=m.resize((int(m.size[0]*k),int(m.size[1]*k)),Image.LANCZOS)
    img=Image.new('RGBA',(W,W),bg or (0,0,0,0))
    white=Image.new('RGBA',m.size,WHITE)
    img.paste(white,((W-m.size[0])//2,(W-m.size[1])//2),m)
    return img.resize((canvas,canvas),Image.LANCZOS)
mark(1024,0.58,bg=GREEN).save('assets/icon/icon.png')
mark(1024,0.60).save('assets/icon/foreground.png')
mark(1024,0.60).save('assets/icon/monochrome.png')
mark(1152,0.40).save('assets/splash/splash_android12.png')
mark(768,0.55).save('assets/splash/splash.png')
