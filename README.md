# TileLayout

A CollectionViewLayout Inspired by Lightbox algorithm http://blog.vjeux.com/2012/image/image-layout-algorithm-lightbox.html.


traverseOpenTiles : looks for the first open point by checking for every point if there exists an indexpath
traverseTilesForPoint : with the first open point and new tile size : frame. The frame is looked point by point if there exists an indexpath. If not, then that point is the starting point for new tile

#############
To compute the layoutattr or frame for indexpath given:

for(section....)
{
	for(row...){
		indexpath : from row and section

		size : from delegate method 

		pointForIndexpath : with the help of traverseOpenTiles

	}
}

 positionByIndexPath : {
    0 =     {	//section
        0 = "NSPoint: {0, 0}";		//row 0 at position (0,0)
        3 = "NSPoint: {100, 80}";
        2 = "NSPoint: {150, 0}";
        1 = "NSPoint: {100, 0}";
    };
}


indexPathByPosition : {
    0 =     {		//x = 0
        0 = "<NSIndexPath: 0xc000000000000016> {length = 2, path = 0 - 0}";		//y = 0 : so at (0,0), indexpath(0,0)
        7 = "<NSIndexPath: 0xc000000000000016> {length = 2, path = 0 - 0}";
        14 = "<NSIndexPath: 0xc000000000000016> {length = 2, path = 0 - 0}";
        .....
         };
    7 =     {
        0 = "<NSIndexPath: 0xc000000000000016> {length = 2, path = 0 - 0}";
        7 = "<NSIndexPath: 0xc000000000000016> {length = 2, path = 0 - 0}";
        14 = "<NSIndexPath: 0xc000000000000016> {length = 2, path = 0 - 0}";
        21 = "<NSIndexPath: 0xc000000000000016> {length = 2, path = 0 - 0}";
        .....
         };

         ....
         }


Block level : smallest block : qtr:qtr based on the full_tile_size




