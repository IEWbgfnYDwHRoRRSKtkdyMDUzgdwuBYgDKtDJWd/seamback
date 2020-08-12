# Import modules
import sys, cv2,dlib, time, argparse
import numpy as np
import faceBlendCommon as fbc
import matplotlib.pyplot as plt

def generate_mask():
  img2 = cv2.imread(IM)
  img1 = cv2.imread('low_res_base_face.jpeg')
  im1Display = cv2.cvtColor(img1, cv2.COLOR_BGR2RGB)
  im2Display = cv2.cvtColor(img2, cv2.COLOR_BGR2RGB)
  img1Warped = np.copy(img2)

  detector = dlib.get_frontal_face_detector()
  predictor = dlib.shape_predictor("shape_predictor_68_face_landmarks.dat")
  points1 = fbc.getLandmarks(detector, predictor, img1)
  points2 = fbc.getLandmarks(detector, predictor, img2) 

  hullIndex = cv2.convexHull(np.array(points2), returnPoints=False)
  hull1 = []
  hull2 = []
  for i in range(0, len(hullIndex)):
    hull1.append(points1[hullIndex[i][0]])
    hull2.append(points2[hullIndex[i][0]])

  imTemp = im2Display.copy()
  numPoints = len(hull2)
  for i in range(0, numPoints):
    cv2.line(imTemp, hull2[i], hull2[(i+1)%numPoints], (255,0,0), 3)
    cv2.circle(imTemp, hull2[i], 5, (0,0,255), -1)
#plt.figure(figsize = (20,10)); plt.imshow(imTemp); plt.axis('off');


  hull8U = []
  for i in range(0, len(hull2)):
    hull8U.append((hull2[i][0], hull2[i][1]))

  mask = np.zeros(img2.shape, dtype=img2.dtype) 
  cv2.fillConvexPoly(mask, np.int32(hull8U), (255, 255, 255))

  m = cv2.moments(mask[:,:,1])
  center = (int(m['m10']/m['m00']), int(m['m01']/m['m00'])) 
  #plt.figure(figsize = (20,10)); plt.imshow(mask); plt.axis('off');
  cv2.imwrite(OUT, mask)

if __name__ == "__main__":
    start_time = time.time()
    ap = argparse.ArgumentParser()
    ap.add_argument("-im", help="Path to video file")
    ap.add_argument("-out", help="Path to video file", required=True)
    #ap.add_argument("-u", help="Use uniform color columns", action='store_true')
    args = vars(ap.parse_args())
    IM, OUT = args["im"], args["out"]

    generate_mask()
