
/**
 * 公司:StrongSoft
 * 创建标识：2012.06.08 TYH 
 * 功能描述：地图图元点击信息展示辅助类，用于模块定位，数据加载，移入，移出等
 * 基于MapFeatureTipHelper对象的改造，使得可以点击PolylineMarker、PolygonMakerExtends这类图元
 * 
 * 
 
 */
package aspage 
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	import flash.geom.Point;
	import flash.net.navigateToURL;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	
	import tileMap.events.MarkerEvent;
	import tileMap.flex.TweenMapComponent;
	import tileMap.geo.Location;
	import tileMap.overlays.MarkerClip;
	
	import tileMapWidgets.data.HttpDataLoader;
	import tileMapWidgets.data.JSON;
	
	/**
	 * 公司:StrongSoft
	 * 创建标识：2012.06.08 TYH 
	 * 功能描述：地图图元点击信息展示辅助类，用于模块定位，数据加载，移入，移出等<br>
	 * 基于MapFeatureTipHelper对象的改造，使得可以点击PolylineMarkerExtends、PolygonMakerExtends这类图元<br>
	 * 
	 * * 修改标志：<br>
	 * tyh 20120716
 	 * 添加MapLayerLegend的点击事件<br>
	 * 并且加载Tip用的关键字依次取oPointMarker.Id>oPointMarker.name
	 * 原因：可以赋给某个特定的图层。
	 */
	public class MapFeatureTipHelperExtends extends Sprite
	{ 
		//地图平台
		private var Map:tileMap.flex.TweenMapComponent;
		//外部传入参数,Json格式，包括图层名称，图层编号，查询语句等
		//private var Args:Object;
		private var Args:Object;
		//具体的信息展示模块
		//private var content:MapFeatureTip;
		private var content:Sprite;
		//图元对象
		private var oPointMarker:Object; 
		
		//构造方法
		//参数args:外部参数,提供图层名称,图层编号等,Json格式
		public function MapFeatureTipHelperExtends(args:*,map:tileMap.flex.TweenMapComponent)
		{ 
			super(); 
			this.Map = map;
			this.Args=args;			
			if(Args.featureinfosqlkey!=undefined&&Args.featureinfosqlkey!="")  //点击图层出现信息展现框
			{
				content = new Sprite();  
				this.addChild(content);				
				Map.utilityLayer.attachMarker(this, new Location(120, 25)); //任意一个经纬度，点击时会根据实际位置调整。
			}
			var MapLayer:MarkerClip = Map.layers.getLayerByName(Args.layername); 
			if(MapLayer!=null){
				MapLayer.addEventListener(MarkerEvent.MARKER_CLICK, onMouseClick); 
			}
			var MapLayerLegend:MarkerClip=Map.layers.getLayerByName("LayerLegend"+Args.layername);
			if(MapLayerLegend!=null){
				MapLayerLegend.addEventListener(MarkerEvent.MARKER_CLICK, onMouseClick); 
			}
			Map.addEventListener(MouseEvent.MOUSE_DOWN, function(event:MouseEvent):void{
				onMarkerOut(null);	
			});
		}
		
//		public function removeEvent(layername:String):void
//		{
//			var MapLayer:MarkerClip = Map.layers.getLayerByName(layername); 
//			if(MapLayer!=null){
//				MapLayer.removeEventListener(MarkerEvent.MARKER_CLICK, onMouseClick); 			
//				Map.removeEventListener(MouseEvent.MOUSE_DOWN, function(event:MouseEvent):void{
//					onMarkerOut(null);	
//				});
//			}
//			else
//			{
//				Alert.show("MapFeatureTipHelper,查无该图层:"+layername);
//			}
//		}
		
		public function Close():void
		{
			if(content!=null&&content.visible) content.visible = false;
		}
		
		//当点击窗口外其它位置隐藏悬浮窗口
		private function onMarkerOut(e:MarkerEvent):void
		{  
			if(content != null && content.visible&&content.stage!=null){				
				if(!content.hitTestPoint(content.stage.mouseX, content.stage.mouseY )){
					content.visible = false;
				}				
			}   			
		} 
		
		
//		public function onClickLegend(name:String):void{
//			var MapLayer:MarkerClip = Map.layers.getLayerByName(Args.layername); 
//			
//			var oDispObj:DisplayObject = MapLayer.getMarker(name);
//			
//			oPointMarker = oDispObj as Object;
//			
//			
//			
//			//悬停：
//			//以下进行展现形式的判定与展现 
//			if(Args.featureinfosqlkey!=undefined&&Args.featureinfosqlkey!=""&&content!=null)
//			{
//				//弹出悬停框				
//				LoadData();
//				toPositionAndShow(Map.center); 
//			}
//			else if(Args.featurelinkformat!=undefined&&Args.featurelinkformat!="")
//			{
//				//弹出链接窗口  
//				var key:String=oPointMarker.hasOwnProperty("id")?oPointMarker.id:oPointMarker.name;
//				var url:String = StringFormatter.format(Args.featurelinkformat,key); 
//				//ExternalInterface.call("window.open",url,"_blank");
//				flash.net.navigateToURL(new flash.net.URLRequest(url),"_blank");
//			}
//			
//		}
		
		//图元点击事件
		private function onMouseClick(e:MarkerEvent):void
		{   			 
			var oDispObj:DisplayObject = e.marker;
			while(oDispObj != null && oDispObj.parent != e.currentTarget)
			{
				oDispObj = oDispObj.parent;
			}
			
			oPointMarker = oDispObj as Object; 
			//以下进行展现形式的判定与展现 
			if(Args.featureinfosqlkey!=undefined&&Args.featureinfosqlkey!=""&&content!=null)
			{
				//弹出悬停框				
				LoadData();
				
				//toPositionAndShow(e.location); 
				toPositionAndShow(Map.map.pointLocation(new Point(Map.mouseX, Map.mouseY)));
			}
			else if(Args.featurelinkformat!=undefined&&Args.featurelinkformat!="")
			{
				//弹出链接窗口  
				var key:String=oPointMarker.hasOwnProperty("id")?oPointMarker.id:oPointMarker.name;
				//var url:String = StringFormatter.format(Args.featurelinkformat,key); 
				//ExternalInterface.call("window.open",url,"_blank");
				//flash.net.navigateToURL(new flash.net.URLRequest(url),"_blank");
			} 
		}
		
		//触发动态加载数据
		private function LoadData():void
		{  
			var key:String=oPointMarker.hasOwnProperty("id")?oPointMarker.id:oPointMarker.name;
			HttpDataHelper.load("../public/DataAccess/GeneralModule/GetFeatureInfo.ashx?SqlKey="+Args.featureinfosqlkey+"&STCD="+key,
				"POST","",
				serviceResult,
				serviceFault);	  
		}
		
		//添加图元到地图并注册图元事件
		private function serviceResult(sender:HttpDataLoader,e:Event):void
		{  			 
			var result:Object = JSON.deserialize(sender.data as String);			 
			var key:String=oPointMarker.hasOwnProperty("id")?oPointMarker.id:oPointMarker.name;
			//content.bulidTitle(oPointMarker.labels[0].text);
			if(result.data!=""&&result.data.length>0)
			{
				//content.updateDraw(result.schema.length,result);  
				var title:String=oPointMarker.hasOwnProperty("featureName")?oPointMarker.featureName:oPointMarker.legendText;
				//content.bulidTitle(title);
				//content.buildContent(result);
				//详细信息 
				//var url:String= StringFormatter.format(Args.link,key);				
				//content.buildLink(url,Map);
				//content.visible=true;
				Alert.show("1_T");
			}
			else
			{
				//Alert.show("查询出错，[0001_prnmsr]查询不到该站点信息!");
			}
			
		}
		
		//HTTPService错误处理	
		private function serviceFault(sender:HttpDataLoader, e:IOErrorEvent):void
		{
			Alert.show(e.text);
		}
		
		
		//定位并显示
		private function toPositionAndShow(location:Location):void
		{  /*
			if(content==null) return;
			var mousePosPoint:Point = Map.map.locationPoint(location);  			
			if(Map.width<=mousePosPoint.x+content.tipWidth) 
			{
				if(Map.height<mousePosPoint.y+content.tipHeight)       //右下
				{
					content.x = -( content.tipWidth);
					content.y = -( content.tipHeight);
				}
				else												   //右上
				{
					content.x = -(content.tipWidth);
					content.y = 0;
				}
			}
			else
			{
				if(Map.height<mousePosPoint.y+content.tipHeight)      //左下
				{
					content.x = 0;
					content.y = -(content.tipHeight);
				}
				else												  //左上
				{
					content.x = 0;
					content.y = 0;
				}
			}		 
			*/
			//更新位置
			Map.utilityLayer.setMarkerLocation(this,location);
			Map.utilityLayer.updateClip(this);	
		} 
		/**
		 *参数1为null或者未定义时用参数2替换
		 * 
		 */ 
		private function isNull(obj:*, alternate:*):* {
			if(obj == null || obj == undefined){
				return alternate;
			}
			return obj;
		} 
	}
}