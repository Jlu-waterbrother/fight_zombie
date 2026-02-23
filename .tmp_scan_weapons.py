from PIL import Image
from collections import deque
img = Image.open('assets/art/image/weapons.png').convert('RGBA')
w, h = img.size
print('size', w, h)
pix = img.load()
visited = [[False]*h for _ in range(w)]
boxes = []
for x in range(w):
    for y in range(h):
        if visited[x][y]:
            continue
        if pix[x, y][3] == 0:
            visited[x][y] = True
            continue
        q = deque([(x, y)])
        visited[x][y] = True
        minx = maxx = x
        miny = maxy = y
        count = 0
        while q:
            cx, cy = q.popleft()
            count += 1
            minx = min(minx, cx)
            maxx = max(maxx, cx)
            miny = min(miny, cy)
            maxy = max(maxy, cy)
            for nx, ny in ((cx+1,cy),(cx-1,cy),(cx,cy+1),(cx,cy-1)):
                if 0 <= nx < w and 0 <= ny < h and not visited[nx][ny]:
                    if pix[nx, ny][3] > 0:
                        visited[nx][ny] = True
                        q.append((nx, ny))
                    else:
                        visited[nx][ny] = True
        if count >= 20:
            boxes.append((minx, miny, maxx, maxy, count))
boxes.sort(key=lambda b: (b[1], b[0]))
print('components', len(boxes))
for i, b in enumerate(boxes):
    minx, miny, maxx, maxy, count = b
    print(i, minx, miny, maxx, maxy, maxx-minx+1, maxy-miny+1, count)
