package DrawMap
{
	import flash.events.MouseEvent;
	
	import tileMap.events.MarkerEvent;
	import tileMap.flex.TweenMapComponent;
	
	import tileMapWidgets.utility.MapManage;
	
	public class DrawLayerHelper
	{
		/**
		 * 绘制面图层  change by hxd 20150717
		 * @param layerName:String  图层名
		 * @param  map:TweenMapComponent   地图控件
		 * @param  data:Array   站点数据
		 * @param  fn_Click:Function  站点点击事件
		 * */
		public static function drawPolygon(layerName:String,map:TweenMapComponent,url:String,fn_Click:Function):void{
			var shpRegion:ShpLayerRegion = new ShpLayerRegion();
			shpRegion.simpleInit(map,{"layername":layerName},url,fn_Click);
		}
		
		/**
		 * 根据数组数据，绘制面图层 
		 * @param layerName
		 * @param map
		 * @param data
		 * @param fn_Click
		 */		
		public static function drawPolygonByArray(layerName:String,map:TweenMapComponent,data:Array,fn_Click:Function):void{
			var shpRegion:ShpLayerRegion = new ShpLayerRegion();
			shpRegion.simpleInit(map,{"layername":layerName},"",fn_Click,data);
		}
		
		/**
		 * 绘制线图层
		 * @param layerName:String  图层名
		 * @param  map:TweenMapComponent   地图控件
		 * @param  data:Array   站点数据
		 * @param  fn_Click:Function  站点点击事件
		 * */	
		public static function drawLine(layerName:String,map:TweenMapComponent,url:String,fn_Click:Function,fn_mouseOver:Function=null,fn_mouseOut:Function=null):void{
			var shpLine:ShpLayerLine = new ShpLayerLine();
			shpLine.simpleInit(map,{"layername":layerName},url,fn_Click,fn_mouseOver,fn_mouseOut);
		}
		
		/**
		 * 根据数组数据绘制线图层 
		 * @param layerName
		 * @param map
		 * @param data
		 * @param fn_Click
		 * @param fn_mouseOver
		 * @param fn_mouseOut
		 */		
		public static function drawLineByArray(layerName:String,map:TweenMapComponent,data:Array,fn_Click:Function,fn_mouseOver:Function=null,fn_mouseOut:Function=null):void{
			var shpLine:ShpLayerLine = new ShpLayerLine();
			shpLine.simpleInit(map,{"layername":layerName},"",fn_Click,fn_mouseOver,fn_mouseOut,data);
		}
		
		/**
		 * 绘制点图层  
		 * @param layerName  图层名
		 * @param map  图片对象
		 * @param data 站点数据
		 * @param fn_Click  fnName(e:MarkerEvent)  带有该参数
		 * 
		 * data 格式：[{"STCD":"YSI0001","STNM":"YSI剖面仪1","LGTD":"118.10470","LTTD":"24.42690","LabelOffsetY":"5","FeatureChar":"67","LabelMinZoom":"9","LabelMaxZoom":"20","size":"20","tag":"YSI剖面仪"}]
		 */		
		public static function drawPoint(layerName:String,map:TweenMapComponent,data:Array,fn_Click:Function,fn_rollOver:Function=null,fn_rollout:Function=null):void{
			var layerManage:MapManage = new MapManage(map);
			//存在该图层，则删除，在绘制
			if(map.layers.getLayerByName(layerName)!=null)
				map.layers.remove(layerName);
			
			layerManage.addLayerFeatures(layerName,data);
			
			if(fn_Click!=null)
				map.layers.getLayerByName(layerName).addEventListener(MarkerEvent.MARKER_CLICK,fn_Click);
			if(fn_rollOver!=null)
				map.layers.getLayerByName(layerName).addEventListener(MarkerEvent.MARKER_ROLL_OVER,fn_rollOver);
			if(fn_rollout!=null)
				map.layers.getLayerByName(layerName).addEventListener(MarkerEvent.MARKER_ROLL_OVER,fn_rollout);
		}
	}
}