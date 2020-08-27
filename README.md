quick solution for extracting paper content in photographs using imagemagick with autoit  
  
  
median the image  
brightness contrast  
canny edge detect  
make hough lines   
  sort the lines found by vertical/horizontal orientation  
    further sort by closeness to the left/right or up/down edges  
      further sort by how close it is to the edge and how long the line is  
those are our 4 lines   
to get the intersection of the lines  
  draw the line and do a median to create blobs  
  connected-components can tell us the centroid positions for these, which we take as the points of intersection  
use those points to do a perspective distort which 'crops' to the paper  
  
for reference later  
  
![example pictures](https://raw.githubusercontent.com/lllllll-llll-llllll/paper-crop-via-hough-lines/master/github/distortion%20fix%201.png?token=AM5DDKENRRUAPKXQ24LV4I27JASLC) 
