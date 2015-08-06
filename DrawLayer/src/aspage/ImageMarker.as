package aspage 
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.geom.Point;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.system.SecurityDomain;
	
	import tileMap.Map;
	import tileMap.core.Coordinate;
	import tileMap.core.TileGrid;
	import tileMap.geo.Location;
	import tileMap.overlays.Redrawable;
	
	import tileMapWidgets.overlays.IImageSourceFactory;
	
	public class ImageMarker extends Sprite implements Redrawable
	{
		private var loaded:Boolean = false;
//		private var imageLoader:Loader;
		private var bottomLeftCoordinate:Coordinate;
		private var topRightCoordinate:Coordinate;
		private var m_bIsEmpty:Boolean = true;
		
		public var loadedCallback:Function; //加载完图的回调函敿
		
		public var bottomLeftLocation:Location;
		public var topRightLocation:Location;
		public var location:Location; //左上角坐栿
		public var imageUrl:String;
		public var map:Map;
		public var loadProgressCallback:Function;
		
		public var zIndex:Number = 0; //用于控制同一个图层中的叠放顺庿
		
		public var imageSourceFactory:IImageSourceFactory;
		public static const ImageMarkerMove:String="ImageMarkerMove";//叠加图层后的移动事件
		
		
		private var spr:Sprite=new Sprite();
		public function ImageMarker(map:Map, minLon:Number, minLat:Number, maxLon:Number, maxLat:Number, loadProgressCallback:Function = null)
		{
			super();
			addChild(spr);
			this.map = map;
			this.bottomLeftLocation = new Location(minLon,minLat);
			this.topRightLocation = new Location(maxLon,maxLat);
			this.location = new Location(minLon,maxLat);
			this.loadProgressCallback = loadProgressCallback;
			
			this.bottomLeftCoordinate = map.getMapProvider().locationCoordinate(this.bottomLeftLocation);
			this.topRightCoordinate = map.getMapProvider().locationCoordinate(this.topRightLocation);
			this.addEventListener(MouseEvent.MOUSE_MOVE,mouseMove);
		}
		
		private function mouseMove(event:MouseEvent):void//叠加图层后的移动事件
		{
			this.map.dispatchEvent(new MouseEvent(ImageMarkerMove));
		}
		
		//================================================= 属性部刿==============================================
		public function get isEmpty():Boolean
		{
			return m_bIsEmpty;
		}
		//================================================= 接口方法 ==============================================
		public function redraw(event:Event=null):void
		{	
			updateGraphics();
		}
		
		//================================================= 方法部分 ==============================================
		public function load(param:Object):void
		{
			this.m_bIsEmpty = false;
			this.loaded = false;
			this.imageUrl = (imageSourceFactory == null ? String(param) : imageSourceFactory.create(param));
			var imageLoader:Loader = new Loader();
			imageLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,onImageLoadError);
			imageLoader.contentLoaderInfo.addEventListener(Event.COMPLETE,onImageLoadComplete);
			
			var lc:LoaderContext=new LoaderContext(true,ApplicationDomain.currentDomain,SecurityDomain.currentDomain);
			imageLoader.load(new URLRequest(this.imageUrl),lc);
			
//			if(imageLoader == null)
//			{
//				imageLoader = new Loader();
//				imageLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,onImageLoadError);
//				imageLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onImageLoadComplete);
//				imageLoader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, onImageLoadProgress);
////				addChild(imageLoader);
//			}
//			else
//			{
//				imageLoader.unload();
//			}
//			imageLoader.load(new URLRequest(this.imageUrl));
		}
		
		public function unLoad():void
		{
//			if(!this.m_bIsEmpty)
//			{
//				imageLoader.unload();
//			}
//			this.m_bIsEmpty = true;
		}
		
		private function updateGraphics():void
		{
			if(this.loaded)
			{
				var grid:TileGrid = map.grid;
				var _oBottomLeftPoint:Point = grid.coordinatePoint(this.bottomLeftCoordinate);
				var _oTopRightPoint:Point = grid.coordinatePoint(this.topRightCoordinate);
				
				spr.scaleX = (_oTopRightPoint.x - _oBottomLeftPoint.x) / map.width;
				spr.scaleY = (_oBottomLeftPoint.y - _oTopRightPoint.y) / map.height;
			}  
		}  
		private function onImageLoadComplete(e:Event):void
		{
			try{
				this.loaded = true;
				var loader:Loader = LoaderInfo(e.target).loader as Loader;
				var imgBD:BitmapData = new BitmapData(loader.width, loader.height,true,0);
				imgBD.draw((loader.content as Bitmap).bitmapData);
				var bm:Bitmap=new Bitmap(imgBD);
				spr.addChild(bm);
				
				updateGraphics();
				if(loadedCallback != null)
				{
					loadedCallback(this,e);
				}
			}catch(e:*){}
		}
		
		private function onImageLoadError(e:IOErrorEvent):void
		{
			this.m_bIsEmpty = true;
		}
		
		private function onImageLoadProgress(e:ProgressEvent):void
		{
			if(loadProgressCallback != null)
			{  
				loadProgressCallback(this, e);
			}
		}
	}
}