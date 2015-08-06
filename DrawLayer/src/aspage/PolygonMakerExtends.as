package aspage 
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.text.*;
	import flash.text.StyleSheet;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.ui.Mouse;
	
	import mx.controls.Alert;
	import mx.core.UIComponent;
	import mx.modules.ModuleBase;
	import mx.utils.StringUtil;
	
	import tileMap.TweenMap;
	import tileMap.core.Coordinate;
	import tileMap.core.TileGrid;
	import tileMap.events.MarkerEvent;
//	import tileMap.flex.MapComponent;
	import tileMap.flex.TweenMapComponent;
	import tileMap.geo.Location;
	import tileMap.overlays.MarkerClip;
	import tileMap.overlays.PolygonClip;
	import tileMap.overlays.PolygonMarker;
	import tileMap.overlays.PolylineMarker;
	import tileMap.overlays.Redrawable;
	
	
//	public class PolygenExtends2 extends TextField implements Redrawable{
//		public var location:Location;
//		public var map:TweenMap;
//		public function PolygenExtends(map:TweenMap){
//			super();
//			this.map=map;
//			this.selectable=false;
//			this.border=true;
//			this.autoSize=TextFieldAutoSize.LEFT;
//		}
//		public function redraw(event:Event = null):void{
//			//Alert.show(this.map.scaleX.toString());
//			this.scaleX=this.map.getZoom();
//			this.scaleY=this.map.getZoom();
//			
//		} 
//	}
	public class PolygonMakerExtends extends PolygonMarker
	{
		

		private var _minVisibleZoom:int=0;
		private var _MaxVisibleZoom:int=int.MAX_VALUE;
		private var _zIndex:int=0;
		private var _featureName:String="";
		
		public function PolygonMakerExtends(map:TweenMap, locations:Array, autoClose:Boolean=true)
		{
			super(map,locations,autoClose);
		}

		/**提示框显示的名字
		 */ 
		public function get featureName():String
		{
			return _featureName;
		}

		public function set featureName(value:String):void
		{
			_featureName = value;
		}

		public function get zIndex():int
		{
			return _zIndex;
		}

		public function set zIndex(value:int):void
		{
			_zIndex = value;
		}

		/**
		 * 最大可视级别
		 * 
		 */ 
		public function get MaxVisibleZoom():int
		{
			return _MaxVisibleZoom;
		}
		
		
		public function set MaxVisibleZoom(value:int):void
		{
			_MaxVisibleZoom = value;
		}
		/**
		 * 最小可视级别
		 * 
		 */ 
		public function get MinVisibleZoom():int
		{
			return _minVisibleZoom;
		}

		public function set MinVisibleZoom(value:int):void
		{
			_minVisibleZoom = value;
		}

		/**
		 * 根据设置决定是通过scale来缩放还是调用画刷来重绘图形
		 * @param	event	事件参数
		 */
		public override  function redraw(event:Event=null):void
		{	
			
			if(map.getZoom() >= this.MinVisibleZoom && map.getZoom() <= this.MaxVisibleZoom){
				this.visible=true;
				super.redraw(event);
			}
			else {
				 this.visible=false;
			}
		}
	}

}