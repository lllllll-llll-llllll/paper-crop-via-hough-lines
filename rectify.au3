#include <array.au3>
#include <file.au3>

;get input files
$files = _FileListToArray(@scriptdir & '\test-input', '*', 1, true)
_ArrayDelete($files, 0)

for $i = 0 to ubound($files) - 1

   $split = stringsplit($files[$i], '\')
   $filename = $split[$split[0]]

   ;image > median > canny edge detection > hough lines transform > line data .mvg
   ;$command = 'magick ' & $files[$i] & ' -statistic median 8x8 -brightness-contrast -50+50 -canny 10x1+10%+5% -hough-lines 20x20+100 lines.mvg'
   ;magick 1.jpg -resize 62500@ -statistic median 8x8 -brightness-contrast -50x50 -canny 10x1+10%%+5%% -hough-lines 20x20+100 lines.jpg
   $command = 'magick ' & $files[$i] & ' -resize 62500@ step_1.jpg'
   runwait(@ComSpec & " /c " & $command, "", @SW_HIDE)

   $command = 'magick step_1.jpg -statistic median 3x50 step_2.jpg'
   runwait(@ComSpec & " /c " & $command, "", @SW_HIDE)

   $command = 'magick step_2.jpg -brightness-contrast -10x10 step_3.jpg'		;instead of brightness contrast, leveling seems to work. in paint.net it involved dragging the mid levels to the very bottom, need to see what the equivalent in IM is.
   runwait(@ComSpec & " /c " & $command, "", @SW_HIDE)

   $command = 'magick step_3.jpg -canny 10x0+10%+5% step_4.jpg'
   runwait(@ComSpec & " /c " & $command, "", @SW_HIDE)

   $command = 'magick step_4.jpg -hough-lines 20x20+50 step_5.jpg'
   runwait(@ComSpec & " /c " & $command, "", @SW_HIDE)

   $command = 'magick step_4.jpg -hough-lines 20x20+50 lines.mvg'
   runwait(@ComSpec & " /c " & $command, "", @SW_HIDE)

   ;$command = 'magick ' & $files[$i] & ' -resize 62500@ -statistic median 3x50 -brightness-contrast -50x50 -canny 10x1+10%+5% -hough-lines 20x20+100 lines.mvg'
   ;runwait(@ComSpec & " /c " & $command, "", @SW_HIDE)

   ;exit

   ;parse line data
   ; best edge data
   ;	 edge      [scr, len, x1, y1, x2, y2]
   local $top    = [999, 0, 0, 0, 0, 0]
   local $left   = [999, 0, 0, 0, 0, 0]
   local $right  = [0, 0, 0, 0, 0, 0]
   local $bottom = [0, 0, 0, 0, 0, 0]

   $lines  = FileReadToArray('lines.mvg')
   $split = stringsplit($lines[1], ' ', 2)
   $width  = $split[3]
   $height = $split[4]
   local $lines_v[0]
   local $lines_h[0]
   local $lines_t[0]
   local $lines_b[0]
   local $lines_l[0]
   local $lines_r[0]

   if ubound($lines) > 3 then
	  ;sort lines into two groups based on their angles
	  for $j = 3 to ubound($lines) - 1
		 $split = stringsplit($lines[$j], ' ', 2)
		 $angle = $split[6]

		 if ($angle > 157.5) or ($angle < 22.5) then
			_arrayadd($lines_v, $j)
		 elseif ($angle > 67.5) and ($angle < 112.5) then
			_arrayadd($lines_h, $j)
		 endif
	  next

	  ;_arraydisplay($lines_v, 'vertical lines')
	  ;_arraydisplay($lines_h, 'horizontal lines')

	  ;vertical lines sorting
	  for $j in $lines_v
		 $split = stringsplit($lines[$j], ' ', 2)
		 $point_1  = $split[1]
		 $point_2  = $split[2]
		 $split = stringsplit($point_1, ',', 2)
		 $x1 = $split[0]
		 $split = stringsplit($point_2, ',', 2)
		 $x2 = $split[0]

		 if ($x1 + $x2) > $width then
			_arrayadd($lines_r, $j)
		 else
			_arrayadd($lines_l, $j)
		 endif
	  next

	  ;_arraydisplay($lines_r, 'right lines')
	  ;_arraydisplay($lines_l, 'left lines')

	  ;horizontal lines sorting
	  for $j in $lines_h
		 $split = stringsplit($lines[$j], ' ', 2)
		 $point_1  = $split[1]
		 $point_2  = $split[2]
		 $split = stringsplit($point_1, ',', 2)
		 $y1 = $split[1]
		 $split = stringsplit($point_2, ',', 2)
		 $y2 = $split[1]

		 if ($y1 + $y2) > $height then
			_arrayadd($lines_b, $j)
		 else
			_arrayadd($lines_t, $j)
		 endif
	  next

	  ;_arraydisplay($lines_t, 'top lines')
	  ;_arraydisplay($lines_b, 'bottom lines')


	  ;pick the leftmost line	-	favor the lowest score
	  for $j in $lines_l
		 $split = stringsplit($lines[$j], ' ', 2)
		 $point_1  = $split[1]
		 $point_2  = $split[2]
		 $distance = $split[5]
		 $split = stringsplit($point_1, ',', 2)
		 $x1 = $split[0]
		 $y1 = $split[1]
		 $split = stringsplit($point_2, ',', 2)
		 $x2 = $split[0]
		 $y2 = $split[1]
		 $score = $x1 + $x2
		 if ($score < $left[0]) and ($distance > $left[1]) then
			$left[0] = $score
			$left[1] = $distance
			$left[2] = $x1
			$left[3] = $y1
			$left[4] = $x2
			$left[5] = $y2
		 endif
	  next

	  ;pick the rightmost line	-	favor the highest score
	  for $j in $lines_r
		 $split = stringsplit($lines[$j], ' ', 2)
		 $point_1  = $split[1]
		 $point_2  = $split[2]
		 $distance = $split[5]
		 $split = stringsplit($point_1, ',', 2)
		 $x1 = $split[0]
		 $y1 = $split[1]
		 $split = stringsplit($point_2, ',', 2)
		 $x2 = $split[0]
		 $y2 = $split[1]
		 $score = $x1 + $x2
		 if ($score > $right[0]) and ($distance > $right[1]) then
			$right[0] = $score
			$right[1] = $distance
			$right[2] = $x1
			$right[3] = $y1
			$right[4] = $x2
			$right[5] = $y2
		 endif
	  next

	  ;pick the topmost line	-	favor the lowest score
	  for $j in $lines_t
		 $split = stringsplit($lines[$j], ' ', 2)
		 $point_1  = $split[1]
		 $point_2  = $split[2]
		 $distance = $split[5]
		 $split = stringsplit($point_1, ',', 2)
		 $x1 = $split[0]
		 $y1 = $split[1]
		 $split = stringsplit($point_2, ',', 2)
		 $x2 = $split[0]
		 $y2 = $split[1]
		 $score = $y1 + $y2
		 if ($score < $top[0]) and ($distance > $top[1]) then
			$top[0] = $score
			$top[1] = $distance
			$top[2] = $x1
			$top[3] = $y1
			$top[4] = $x2
			$top[5] = $y2
		 endif
	  next

	  ;pick the bottommost line	-	favor the highest score
	  for $j in $lines_b
		 $split = stringsplit($lines[$j], ' ', 2)
		 $point_1  = $split[1]
		 $point_2  = $split[2]
		 $distance = $split[5]
		 $split = stringsplit($point_1, ',', 2)
		 $x1 = $split[0]
		 $y1 = $split[1]
		 $split = stringsplit($point_2, ',', 2)
		 $x2 = $split[0]
		 $y2 = $split[1]
		 $score = $y1 + $y2
		 if ($score > $bottom[0]) and ($distance > $bottom[1]) then
			$bottom[0] = $score
			$bottom[1] = $distance
			$bottom[2] = $x1
			$bottom[3] = $y1
			$bottom[4] = $x2
			$bottom[5] = $y2
		 endif
	  next

   endif

   #cs
   $command = 'magick -size '& $width & 'x' & $height& ' xc:white -stroke red -draw "line '& $top[2] & ',' & $top[3] & ' ' & $top[4] & ',' & $top[5] &'" line_top.png'
   runwait(@ComSpec & " /c " & $command, "", @SW_HIDE)
   $command = 'magick -size '& $width & 'x' & $height& ' xc:white -stroke blue -draw "line '& $bottom[2] & ',' & $bottom[3] & ' ' & $bottom[4] & ',' & $bottom[5] &'" line_bottom.png'
   runwait(@ComSpec & " /c " & $command, "", @SW_HIDE)
   $command = 'magick -size '& $width & 'x' & $height& ' xc:white -stroke green -draw "line '& $left[2] & ',' & $left[3] & ' ' & $left[4] & ',' & $left[5] &'" line_left.png'
   runwait(@ComSpec & " /c " & $command, "", @SW_HIDE)
   $command = 'magick -size '& $width & 'x' & $height& ' xc:white -stroke orange -draw "line '& $right[2] & ',' & $right[3] & ' ' & $right[4] & ',' & $right[5] &'" line_right.png'
   runwait(@ComSpec & " /c " & $command, "", @SW_HIDE)
   #ce


   ;draw lines
   $command = 'magick -size '& ($width + 30) & 'x' & ($height + 30) & ' xc:white -stroke black -strokewidth 5 -draw "line '& $top[2]+15 & ',' & $top[3]+15 & ' ' & $top[4]+15 & ',' & $top[5]+15 &'" -draw "line '& $bottom[2]+15 & ',' & $bottom[3]+15 & ' ' & $bottom[4]+15 & ',' & $bottom[5]+15 &'" -draw "line '& $left[2]+15 & ',' & $left[3]+15 & ' ' & $left[4]+15 & ',' & $left[5]+15 &'" -draw "line '& $right[2]+15 & ',' & $right[3]+15 & ' ' & $right[4]+15 & ',' & $right[5]+15 &'" lines.png'
   runwait(@ComSpec & " /c " & $command, "", @SW_HIDE)

   ;add border
   ;$command = 'magick lines.png +append -bordercolor white -border 15x15 test_1.png'
   ;runwait(@ComSpec & " /c " & $command, "", @SW_HIDE)

   ;median
   $command = 'magick lines.png -statistic median 12x12 -blur 0x8 -brightness-contrast -66x100 test_1.png'
   runwait(@ComSpec & " /c " & $command, "", @SW_HIDE)

   ;islands
   $command = 'magick test_1.png -negate -define connected-components:verbose=true -connected-components 4 -auto-level -depth 8 objects.png > islands.txt'
   runwait(@ComSpec & " /c " & $command, "", @SW_HIDE)

   ;get the source dimensions
   $command = 'magick identify -format %wx%h ' & $files[$i] & ' > info.txt'
   runwait(@ComSpec & " /c " & $command, "", @SW_HIDE)
   $info = FileRead('info.txt')
   $split = stringsplit($info, 'x', 2)
   $w = int($split[0])
   $h = int($split[1])
   ;msgbox(1,'full width', '>' &$w& '<')
   ;msgbox(1,'full height', '>' &$h& '<')
   ;msgbox(1,'thumb width', '>' &$width& '<')
   ;msgbox(1,'thumb height', '>' &$height& '<')
   $scale = $w / $width

   ;iterate through islands.txt
   $islands = FileReadToArray('islands.txt')
   local $o[16]
   for $j = 1 to ubound($islands) - 1
	  $split = stringsplit($islands[$j], ' ', 2)
	  $point = $split[4]
	  $area  = $split[5]
	  if ($area > 100) and ($area < 1000) then
		 $split = stringsplit($point, ',', 2)
		 $x = $split[0]
		 $y = $split[1]
		 $trim_percent = 0.01

		 if $x < ($width+30) / 2 and $y < ($height+30) / 2 then	;top left
			$o[0] = int(($x-15) * $scale) + ($w * $trim_percent)
			$o[1] = int(($y-15) * $scale) + ($h * $trim_percent)
			$o[2] = 0
			$o[3] = 0
		 elseif $x < ($width+30) / 2 and $y > ($height+30) / 2 then	;bottom left
			$o[4] = int(($x-15) * $scale) + ($w * $trim_percent)
			$o[5] = int(($y-15) * $scale) - ($h * $trim_percent)
			$o[6] = 0
			$o[7] = $h
		 elseif $x > ($width+30) / 2 and $y > ($height+30) / 2 then	;bottom right
			$o[8] = int(($x-15) * $scale) - ($w * $trim_percent)
			$o[9] = int(($y-15) * $scale) - ($h * $trim_percent)
			$o[10] = $w
			$o[11] = $h
		 elseif $x > ($width+30) / 2 and $y < ($height+30) / 2 then	;top right
			$o[12] = int(($x-15) * $scale) - ($w * $trim_percent)
			$o[13] = int(($y-15) * $scale) + ($h * $trim_percent)
			$o[14] = $w
			$o[15] = 0
		 endif

	  endif

   next

   ;_arraydisplay($o, 'points')

   ;apply corrective distortion
   $output = @scriptdir & '\test-output\' & $filename
   $command = 'convert ' &  $files[$i] & ' -matte -virtual-pixel transparent -auto-level -distort perspective "' & _
																								     $o[0]&		','		&$o[1]&		' '		&$o[2]&		','		&$o[3]& _
																								' ' &$o[4]&		','		&$o[5]&		' '		&$o[6]&		','		&$o[7]& _
																								' ' &$o[8]&		','		&$o[9]&		' '		&$o[10]&	','		&$o[11]& _
																								' ' &$o[12]&	','		&$o[13]&	' '		&$o[14]&	','		&$o[15]& _
																								'" ' & $output
   ;msgbox(1,'',$command)
   runwait(@ComSpec & " /c " & $command, "", @SW_HIDE)

   ;exit
   ;msgbox(1,'paused', 'please look over the data')




;		"_,_,_,_   _,_,_,_   _,_,_,_   _,_,_,_ "



next



;iterate through line data

;vertical edge candidates are:
;majority-vertical lines

;horizontal edge candiates are:
;majority-horizontal lines

;we find the loewst in x, y greatest in x,y to get the 1234, found by ading the coordiates of each endpoint and going with the smallest/largest...

#cs

   $point_1  = $split[1]
   $point_2  = $split[2]
   $angle    = $split[6]
   $distance = $split[5]

$split = stringsplit($point_1, ',', 2)
   $x1 = $split[0]
   $y1 = $split[1]

$split = stringsplit($point_2, ',', 2)
   $x2 = $split[0]
   $y2 = $split[1]


   if ($angle < 30) or ($angle > 150) then
	  if ($score_x > $right[0]) and ($distance > $right[1]) then
		 ;msgbox(1, 'right best set to', 'line ' & $j - 2)
		 $right[0] = $score_x
		 $right[1] = $distance
		 $right[2] = $x1
		 $right[3] = $y1
		 $right[4] = $x2
		 $right[5] = $y2
	  endif

	  if ($score_x < $left[0]) and ($distance > $left[1]) then
		 ;msgbox(1, 'left best set to', 'line ' & $j - 2)
		 $left[0] = $score_x
		 $left[1] = $distance
		 $left[2] = $x1
		 $left[3] = $y1
		 $left[4] = $x2
		 $left[5] = $y2
	  endif

   elseif ($angle < 120) and ($angle > 60) then
	  $score_y    = $y1 + $y2
	  if ($score_y > $bottom[0]) and ($distance > $bottom[1]) then
		 ;msgbox(1, 'bottom best set to', 'line ' & $j - 2)
		 $bottom[0] = $score_y
		 $bottom[1] = $distance
		 $bottom[2] = $x1
		 $bottom[3] = $y1
		 $bottom[4] = $x2
		 $bottom[5] = $y2
	  endif

	  if ($score_y < $top[0]) and ($distance > $top[1]) then
		 ;msgbox(1, 'top best set to', 'line ' & $j - 2)
		 $top[0] = $score_y
		 $top[1] = $distance
		 $top[2] = $x1
		 $top[3] = $y1
		 $top[4] = $x2
		 $top[5] = $y2
	  endif

   endif

#ce