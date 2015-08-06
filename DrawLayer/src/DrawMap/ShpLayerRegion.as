/*
* 创建：tyh
* 时间：20120518
* 功能：实现面图元的加载，如区域、流域、范围
*
*Lo1_mapMenu配置如下例如：../Data/ShpLayer.swf|0,0,0|{"layername":"图层展示","MapLayerConfigMapid":"3"}
*/
package DrawMap 
{
	//import aspage.LayerLine;
	import aspage.LayerPolygon;
	import aspage.MapFeatureTipHelperExtends;
	import aspage.PolygonMakerExtends;
	
	import flash.display.DisplayObject;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.utils.Timer;
	
	import mx.controls.Alert;
	import mx.modules.ModuleBase;
	
	import tileMap.flex.TweenMapComponent;
	import tileMap.overlays.MarkerClip;
	import tileMap.overlays.PolygonClip;
	import tileMap.overlays.PolygonMarker;
	
	
	public class ShpLayerRegion extends ModuleBase // implements IMapApplicationModule
	{
		private var m_bSuspend:Boolean = false;
		
		private var PolygonLayer:PolygonClip;//地图缩放而缩放的标记对象容器，通常用于管理线、面对象，例如向地图添加某个地区的边界线，或叠加云图等。
		private var LegendLayer:MarkerClip;//地图标记对象的图层
		private var m_oMap:tileMap.flex.TweenMapComponent;
		
		//MapLayerConfig中配置的Id
		private var MapLayerConfigMapid:String="";
		private var Args:*; 
		private var LegendUrl:String="";//图例的url地址。要相对于地图主应用
		private var LegendName:String="";//图例的名称
		
		private var FeatureHelper:MapFeatureTipHelperExtends;
		private var tempColor:uint;
		public var timer:Timer;   
		private var plolymaker:PolygonMakerExtends;
		
		private var m_clickFun_ShpLayerRegion:String="";//点击外部调用的方法名
		
		/**
		 * 测试时用的 
		 */
		//private var LineTool:LayerLine;
		private var PolygonTool:LayerPolygon;
		
		public function ShpLayerRegion()
		{
			super();
		}
		//==========================================================鼠标事件=====================================
		/**
		 * 面图层点击事件
		 * @param e
		 */		
		private function PolygonMouseClike(e:MouseEvent):void
		{
			var pMarker:PolygonMakerExtends = e.currentTarget  as PolygonMakerExtends;				
			ExternalInterface.call(m_clickFun_ShpLayerRegion,pMarker.featureName,pMarker.name);
		}
		/**
		 * 鼠标移动上面图层
		 * @param e
		 */		
		private function PolygonMouseOver(e:MouseEvent):void
		{
			plolymaker=(e.currentTarget  as PolygonMakerExtends);
			tempColor=plolymaker.fillColor;
			
			if(!timer){
				timer = new Timer(1000); 
			}
			timer.addEventListener(TimerEvent.TIMER,timehandle);   
			timer.start();   
			
		}
		/**
		 * 定时操作
		 * @param e
		 */		
		private function timehandle(e:TimerEvent):void  
		{   
			if(plolymaker){
				if(tempColor==0xF70B10)
				{
					plolymaker.fillColor=0xF70B10;
					plolymaker.lineColor=0xF70B10;
				}
				else{
					plolymaker.fillColor=tempColor;
					plolymaker.lineColor=tempColor;
				}
				plolymaker.redraw();
			}
			
		}   
		/**
		 * 鼠标移出
		 * @param e
		 */		
		private function PolygonMouseOut(e:MouseEvent):void
		{
			
			timer.removeEventListener(TimerEvent.TIMER,timehandle);
			timer.stop();
			if(plolymaker){
				plolymaker.fillColor=tempColor;
				plolymaker.lineColor=tempColor;
			}
		}
		//=========================================== 接口方法 ============================================
		public function dispose():void {
			m_bSuspend=false;
		}
		
		public function setStyle(a:*,b:*):void
		{
			
		}
		
		/**
		 * 初始化
		 * @param map
		 * @param params
		 */		
		public function init(map:tileMap.flex.TweenMapComponent, params:* = null,url:String=""):void {
			m_oMap = map;
			//Alert.show(String(params));
			Args = params;
			//Args = JSON.deserialize(params as String);  
			
			//PolygonLayer=m_oMap.layers.add((Args.layername,true,1) as PolygonClip;//添加面图层
			var markerClip:MarkerClip = m_oMap.layers.add(Args.layername,true);
			PolygonLayer = markerClip as PolygonClip;
			LegendLayer=m_oMap.layers.add("PolygonLayerLegengd"+Args.layername,false);//添加与面对应的标签图层
			//LegendLayer.name="PolygonLayerLegengd";
			//Args.layername="PolygonLayerLegengd";
			
			MapLayerConfigMapid=Args.MapLayerConfigMapid;
			LegendName=Args.LegendName;
			var a:Object=Args.LegendUrl;
			
			if(Args.clickFun&&Args.clickFun!=""){
				m_clickFun_ShpLayerRegion=Args.clickFun;
			}
			
			if(Args.LegendUrl){
				LegendUrl="Images/"+Args.LegendUrl;
			}
			
			PolygonTool=new LayerPolygon(map,MapLayerConfigMapid,PolygonLayer,LegendLayer);
			
			//设置面图层的数据请求路径
			PolygonTool.s_polygonUrl = url;
			
			PolygonTool.clickfn=m_clickFun_ShpLayerRegion==""?null:PolygonMouseClike;
			if(Args.polygonUrl&&Args.polygonUrl!=""){
				PolygonTool.s_polygonUrl=Args.polygonUrl;
			}
			if(LegendUrl!=""){
				m_oMap.parentApplication.callModuleMethod("../Public/ImageMarkerFactoryForMap.swf", "showLegend", ["Shp"+MapLayerConfigMapid, LegendName,LegendUrl]);
			}
			initData();
			
			PolygonTool.mouseOverfn=PolygonMouseOver;
			PolygonTool.mouseOutfn=PolygonMouseOut;
			if(Args.featureinfosqlkey&&Args.featureinfosqlkey!=""){
				FeatureHelper = new  MapFeatureTipHelperExtends(Args,m_oMap);
			}
			ExternalInterface.addCallback("ShpLayerRegion_Suspend_" + Args.layername, suspend);
			ExternalInterface.addCallback("ShpLayerRegion_Resume_" + Args.layername, resume);
		}
		
		
		/**
		 * 初始化数据 
		 */		
		public function initData():void{
			PolygonTool.initData();
		}
		
		/**
		 * 重新开始/继续  
		 */		
		public function resume():void {
			
			m_bSuspend = false;
			if(LegendUrl!=""){
				m_oMap.parentApplication.callModuleMethod("../Public/ImageMarkerFactoryForMap.swf", "showLegend", ["Shp"+MapLayerConfigMapid, LegendName,LegendUrl]);
			}
			PolygonTool.Resume();
		}
		
		/**
		 * 挂起 
		 */		
		public function suspend():void
		{
			m_bSuspend = true;
			
			//LineTool.ClearMarkers();
			PolygonTool.ClearMarkers();
			//隐藏图例
			m_oMap.parentApplication.callModuleMethod("../Public/ImageMarkerFactoryForMap.swf", "hideLegend", ["Shp"+MapLayerConfigMapid]);
		}
		
		/*----------------------绘制简单的面图层   by  hxd  start  20150423-----------------------*/
		/**
		 * 简单的绘制面图层
		 * @param map 地图对象
		 * @param params 参数[图层名...等]
		 * @param url [图层数据参数]
		 * @param clickHandler 图层点击处理函数
		 * @param data 多边形数据
		 */		
		public function simpleInit(map:tileMap.flex.TweenMapComponent, params:* = null,url:String="",clickHandler:Function=null,data:Array=null):void {
			m_oMap = map;
			Args = params;
			
			var markerClip:MarkerClip = m_oMap.layers.add(Args.layername,true);
			PolygonLayer = markerClip as PolygonClip;
			LegendLayer=m_oMap.layers.add("PolygonLayerLegengd"+Args.layername,false);//添加与面对应的标签图层
			
			LegendLayer.addEventListener(MouseEvent.CLICK,clickHandler);
			
			//1. 创建多边形对象
			PolygonTool=new LayerPolygon(map,MapLayerConfigMapid,PolygonLayer,LegendLayer,Args.layername);
			
			//2. 设置面图层的数据请求路径
			PolygonTool.s_polygonUrl = url;
			
			//3. 设置点击事件
			PolygonTool.clickfn=clickHandler;
			
			//4. 初始化数据
			if(data!=null)
				PolygonTool.drawPolygonByArray(data);
			else
				initData();
		}
		/*----------------------绘制简单的面图层   by  hxd  end  20150423-----------------------*/
	}
}