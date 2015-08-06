// ActionScript file
/*
* 创建：tyh     
* 时间：20120518
* 功能：实现面图元的加载，如区域、流域、范围
* 修改: hxd  
* 时间: 20150717
*Lo1_mapMenu配置如下例如：../Data/ShpLayerLine.swf|0,0,0|{"layername":"图层展示","MapLayerConfigMapid":"3"}
*/
package DrawMap 
{
	import aspage.LayerLine;
	import aspage.MapFeatureTipHelperExtends;
	
	import flash.display.DisplayObject;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	
	import mx.controls.Alert;
	import mx.modules.ModuleBase;
	
	import tileMap.flex.TweenMapComponent;
	import tileMap.overlays.MarkerClip;
	import tileMap.overlays.PolygonClip;
	import tileMap.overlays.PolylineMarker;
	
	import tileMapWidgets.data.JSON;
	
	public class ShpLayerLine extends ModuleBase 
	{
		private var m_bSuspend:Boolean = false;
		
		private var PolygonLayer:PolygonClip;//地图缩放而缩放的标记对象容器，通常用于管理线、面对象，例如向地图添加某个地区的边界线，或叠加云图等。
		//private var LegendLayer:MarkerClip;//地图标记对象的图层
		private var m_oMap:tileMap.flex.TweenMapComponent;
		
		//MapLayerConfig中配置的Id
		private var MapLayerConfigMapid:String="";
		private var Args:*; 
		//private var Type:String="";//图层类别,Polygon面图层，polyline线图层
		private var LegendUrl:String="";//图例的url地址。要相对于地图主应用
		private var LegendName:String="";//图例的名称
		
		private var FeatureHelper:MapFeatureTipHelperExtends;
		private var tempColor:uint;
		
		/**
		 * 画线对象 
		 */
		private var LineTool:LayerLine;
		
		public function ShpLayerLine()
		{
			super();
		}
		//==========================================================鼠标事件=====================================
		
		private function PolylineMouseClike(e:MouseEvent):void
		{
			Alert.show((e.currentTarget  as PolylineMarker).name);
		}
		private function PolylineMouseOver(e:MouseEvent):void
		{
			tempColor=(e.currentTarget  as PolylineMarker).lineColor;
			(e.currentTarget  as PolylineMarker).lineColor=0xFFFFFF;
			
		}
		private function PolylineMouseOut(e:MouseEvent):void
		{
			
			(e.currentTarget  as PolylineMarker).lineColor=tempColor;
		}
		//=========================================== 接口方法 ============================================
		public function dispose():void {
			m_bSuspend=false;
		}
		
		public function init(map:tileMap.flex.TweenMapComponent, params:* = null):void {
			m_oMap = map;
			Args = JSON.deserialize(params as String);  
			
			PolygonLayer=m_oMap.layers.add(Args.layername,true,1) as PolygonClip;
			
			MapLayerConfigMapid=Args.MapLayerConfigMapid;
			LegendName=Args.LegendName;
			var a:Object=Args.LegendUrl;
			if(Args.LegendUrl){
				LegendUrl="Images/"+Args.LegendUrl;
			}
			LineTool=new LayerLine(map,MapLayerConfigMapid,PolygonLayer);
			
			if(LegendUrl!=""){
				m_oMap.parentApplication.callModuleMethod("../Public/ImageMarkerFactoryForMap.swf", "showLegend", ["Shp"+MapLayerConfigMapid, LegendName,LegendUrl]);
			}
			initData();
			//LineTool.clickfn=PolylineMouseClike;
			LineTool.mouseOverfn=PolylineMouseOver;
			LineTool.mouseOutfn=PolylineMouseOut;
			//Args.featureinfosqlkey="CA_S_GetCA_Infor_TYH";
			if(Args.featureinfosqlkey&&Args.featureinfosqlkey!=""){
				FeatureHelper = new  MapFeatureTipHelperExtends(Args,m_oMap);
			}
		}
		
		public function initData():void{
			LineTool.initData();
		}
		public function resume():void {
			
			
			m_bSuspend = false;
			if(LegendUrl!=""){
				m_oMap.parentApplication.callModuleMethod("../Public/ImageMarkerFactoryForMap.swf", "showLegend", ["Shp"+MapLayerConfigMapid, LegendName,LegendUrl]);
			}
			LineTool.Resume();
		}
		public function suspend():void
		{
			m_bSuspend = true;
			LineTool.ClearMarkers();
			//隐藏图例
			m_oMap.parentApplication.callModuleMethod("../Public/ImageMarkerFactoryForMap.swf", "hideLegend", ["Shp"+MapLayerConfigMapid]);
		}
		
		/*=======================================绘制简单的面图层   by  hxd  start  20150423====================================*/
		/**
		 * 简单的绘制面图层
		 * @param map 地图对象
		 * @param params 参数[图层名...等]
		 * @param url [图层数据参数]
		 * @param clickHandler 图层点击处理函数
		 * @param mouseOver    鼠标移入时间
		 * @param moustOut     鼠标移除时间
		 */		
		public function simpleInit(map:tileMap.flex.TweenMapComponent, params:* = null,url:String="",clickHandler:Function=null,mouseOver:Function=null,moustOut:Function=null,data:Array=null):void {
			m_oMap = map;
			Args = params;
			PolygonLayer=m_oMap.layers.add(Args.layername,true,1) as PolygonClip;
			
			MapLayerConfigMapid=Args.MapLayerConfigMapid;
			
			LineTool=new LayerLine(map,MapLayerConfigMapid,PolygonLayer);
			LineTool.polyLineUrl = url;
			
			//4. 初始化数据
			if(data!=null)
				LineTool.drawLineByArray(data);
			else
				initData();
			if(clickHandler!=null)
				LineTool.clickfn = clickHandler;
			if(mouseOver!=null)
				LineTool.mouseOverfn=mouseOver;
			if(moustOut!=null)
				LineTool.mouseOutfn=moustOut;
		}
		/*----------------------绘制简单的面图层   by  hxd  end  20150423-----------------------*/
	}
}