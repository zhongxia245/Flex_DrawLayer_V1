package aspage 
{
	import flash.display.DisplayObject;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.controls.Alert;
	
	import tileMap.TweenMap;
	import tileMap.events.MarkerEvent;
	import tileMap.flex.TweenMapComponent;
	import tileMap.geo.*;
	import tileMap.overlays.MarkerClip;
	import tileMap.overlays.PolygonClip;
	import tileMap.overlays.PolygonMarker;
	
	import tileMapWidgets.data.HttpDataLoader;
	import tileMapWidgets.data.JSON;
	import tileMapWidgets.overlays.PointMarker;
	
	
	public class LayerPolygon
	{
		
		private var m_oMap:TweenMapComponent;
		private var PolygonLayer:PolygonClip;//地图缩放而缩放的标记对象容器，通常用于管理线、面对象，例如向地图添加某个地区的边界线，或叠加云图等。
		private var LegendLayer:MarkerClip;//地图标记对象的图层
		//面图层的背景色列表，共16种，数量超过16种的话，自行控制，比如索引又从头开始
		public var backColors:Object=[0x00FF00,0xFF00FF,0xFF8B02,0x0284FF,0x05FFCD,0xBDFF02,0xFF001A,0x5C00FF,0x0100FF,0x02FF88,0xE7FF05,0xFF0044,0xFF0C02,0x7DFF05,0x05FFFA,0x7E08FF];
		
		private var polygonUrl:String="StaticLayerDataProvider.ashx";
		//MapLayerConfig中配置的Id
		private var MapLayerConfigMapid:String="";
		
		public var polygonStyle:*={styles:{ "lineColor":"0x000000","lineThickness":"1","fillColor":"0x000000","fillAlpha":"0.5","colors":[] }};//面图层的默认样式
		public var polygonLegendStyle:*=
			{styles:{"legendFontSize":"14","legendFont":"SimSun","legendImage":"","legendColor":"0x000000"}};
		private var _PolygonMarkers:*={};//缓存图层对象
		private var _PolyLegendMarkers:*={};//区域标注	
		
		//=========保存中心经纬度,  START hxd 20150423  厦门工业企业信息系统
		private var _locations:Object = new Object();  //存放每个面的中间经纬度
		//=========保存中心经纬度,  START hxd 20150423  厦门工业企业信息系统
		
		/**
		 * 配置信息加载路径
		 * @param value
		 */
		public function set s_polygonUrl(value:String):void
		{
			polygonUrl=value;
		}
		
		/**
		 *获取  配置信息加载路径
		 */
		public function get s_polygonUrl():String
		{
			return polygonUrl;
		}
		
		
		/**设置面涂层面对象的事件的处理函数，设置为null将移除原有的侦听
		 * @param value 方法签名 function(e:MouseEvent):void
		 *{
		 * //获取相关数据信息
		 * e.currentTarget  as PolygonMakerExtends;
		 *}
		 */ 
		public function set mouseOutfn(value:Function):void
		{
			var polymaker:PolygonMakerExtends;
			for(var key:String in _PolygonMarkers)
			{
				polymaker = _PolygonMarkers[key];
				if(polymaker){
					if(_mouseOutfn!=null){
						polymaker.removeEventListener(MouseEvent.MOUSE_OUT,_mouseOutfn);
					}
					if(value!=null)
						polymaker.addEventListener(MouseEvent.MOUSE_OUT,value);
				} 
			}
			_mouseOutfn = value;
		}
		
		/**设置面涂层面对象的MOUSE_OVER事件的处理函数，设置为null将移除原有的侦听
		 * @param value 方法签名 function(e:MouseEvent):void
		 *{
		 * //获取相关数据信息
		 * e.currentTarget  as PolygonMakerExtends;
		 *}
		 */  
		public function set mouseOverfn(value:Function):void
		{
			var polymaker:PolygonMakerExtends;
			for(var key:String in _PolygonMarkers)
			{
				polymaker = _PolygonMarkers[key];
				if(polymaker){
					if(_mouseOverfn!=null){
						polymaker.removeEventListener(MouseEvent.MOUSE_OVER,_mouseOverfn);
					}
					if(value!=null)
						polymaker.addEventListener(MouseEvent.MOUSE_OVER,value);
				} 
			}
			_mouseOverfn = value;
		}
		
		private var _clickfn:Function=null;
		private var _mouseOverfn:Function=null;
		private var _mouseOutfn:Function=null;
		
		/**设置面涂层面对象的CLICK事件的处理函数，设置为null将移除原有的侦听
		 * @param value 方法签名 function(e:MouseEvent):void
		 *{
		 * //获取相关数据信息
		 * e.currentTarget  as PolygonMakerExtends;
		 *}
		 */ 
		public function set clickfn(value:Function):void
		{
			
			var polymaker:PolygonMakerExtends;
			for(var key:String in _PolygonMarkers)
			{
				polymaker = _PolygonMarkers[key];
				if(polymaker){
					if(_clickfn!=null){
						polymaker.removeEventListener(MouseEvent.CLICK,_clickfn);
					}
					if(value!=null)
						polymaker.addEventListener(MouseEvent.CLICK,value);
				} 
			}
			_clickfn = value;
		}
		/**
		 * 面图对象的个数
		 */ 
		private var _PolygonMarkersNum:int=0;
		/**
		 * tyh20120607
		 * 封装面图层的相关操作，主要包括产生线图并绘制对象，包装点击、悬停事件
		 * 
		 */ 
		public function LayerPolygon(map:TweenMapComponent,MapLayerConfigMapid:String,Clip:PolygonClip,LegendLayer:MarkerClip,datakey:String="")
		{
			this.m_oMap=map;
			this.PolygonLayer=Clip;
			this.LegendLayer=LegendLayer;
			this.MapLayerConfigMapid=MapLayerConfigMapid;
		}
		/**
		 * 面上的标记对象的缓存
		 */ 
		public function get PolyLegendMarkers():*
		{
			return _PolyLegendMarkers;
		}
		
		public function set PolyLegendMarkers(value:*):void
		{
			_PolyLegendMarkers = value;
		}
		/**
		 * 获取面对象缓存
		 */ 
		public function get PolygonMarkers():*
		{
			return _PolygonMarkers;
		}
		
		private function set PolygonMarkers(value:*):void
		{
			_PolygonMarkers = value;
		}
		
		/**
		 * 画面（多边形）图
		 * @param zIndex为Array数据的索引
		 * @param item Array数组中的对象
		 */  
		public function drawPolygon(zIndex:int,item:*):void
		{
			zIndex=isNull(item.zIndex,zIndex);
			//var idno:String=item.idno;
			var idno:String=isNull(item.idno,item.attributes.IDNO);
			var featureName:String=isNull(item.featureName,item.attributes.NAME);
			var data:Array=item.data;
			var thispolygonStyle:*=JsonHelper.combin(polygonStyle.styles, item.styles);
			var polygonLegendStyle:*=JsonHelper.combin(polygonLegendStyle.styles, item.polygonLegendStyle);
			
			if(!item.styles||!item.styles.fillColor){//没有配置颜色
				thispolygonStyle.fillColor=backColors[_PolygonMarkersNum%16];//只定义了16种颜色tyh,超过索引的又重头开始赋值
				thispolygonStyle.lineColor=backColors[_PolygonMarkersNum%16];
			}
			
			if(item.styles.colors!=null && item.styles.colors.length>0){
				for(var j:int = 0; j<item.styles.colors.length; i++){
					if(item.styles.colors[j].filterText != null){
						if(featureName.indexOf(item.styles.colors[j].filterText)>=0){
							
							thispolygonStyle.fillColor = item.styles.colors[j].fillColor;
							thispolygonStyle.lineColor = item.styles.colors[j].lineColor;
							break;
						}  
					}
				}
			}
			/*=======================START 20150806 by hxd============*/
			/*处理一个站点有多条线,或者只有一条线的处理*/
			if(data[0] is Array){
			}else{
				data = [data];
			}
			/*====================END  20150806 by hxd=================*/
			for(var i:int=0;i<data.length;i++){
				var arr:Array=new Array();
				for(var k:int = 0;k<data[i].length;k++)
				{
					arr.push(new Location(data[i][k].x,data[i][k].y));
				}
				
				var X:Number=0;
				var Y:Number=0;
				
				data[i].forEach(function(item:*, index:int, array:Array):void{
					X=(X*index+item.x)/(index+1);//平均值计算获取数据中心点
					Y=(Y*index+item.y)/(index+1);
				},null);
				
				X=isNull(polygonLegendStyle.LocationX,X);//配置的中心
				Y=isNull(polygonLegendStyle.LocationY,Y);
				
				var center:Location;
				center=new Location(X,Y);
				
				var label:PointMarker=null;
				var isShowTitle:Boolean=polygonLegendStyle.legendFontSize&&polygonLegendStyle.legendFontSize!="0"&&polygonLegendStyle.legendFontSize!="";
				
				if(isShowTitle){
					label=new PointMarker(m_oMap.map,idno,center);
					label.legendText=featureName;
					label.legendFontSize=polygonLegendStyle.legendFontSize;
					label.legendFont=polygonLegendStyle.legendFont;
					label.legendBorderColor=0xFFFFFF;
					label.legendBorderAlpha=0.7;
					if(polygonLegendStyle.legendImage!="")
						label.legendImage=polygonLegendStyle.legendImage;
					label.maxVisibleZoom=isNull(item.maxVisibleZoom,int.MAX_VALUE);
					label.minVisibleZoom=isNull(item.minVisibleZoom,1);
					label.legendColor=polygonLegendStyle.legendColor;
					label.location=center;
					
					//绘制图层
					drawSimplePolygon(m_oMap.map,arr,idno+i,featureName,zIndex,isShowTitle,label,thispolygonStyle);
				}
				
			}
		}
		
		/**
		 * 绘制多面区域
		 */		
		public function drawSimplePolygon(map:TweenMap,data:Array,idno:String,featureName:String,zIndex:int,isShowTitle:Boolean,label:PointMarker,thispolygonStyle:Object):void{
			var polygon:PolygonMakerExtends=new PolygonMakerExtends(map,data);  //创建多边形图元
			
			if(_clickfn!=null)
				polygon.addEventListener(MouseEvent.CLICK,_clickfn);
			if(_mouseOverfn!=null)
				polygon.addEventListener(MouseEvent.MOUSE_OVER,_mouseOverfn);
			if(_mouseOutfn!=null){ 
				polygon.addEventListener(MouseEvent.MOUSE_OUT,_mouseOutfn);
			}
			polygon.fill=true;    //设置允许填充
			polygon.fillColor=isNull(thispolygonStyle.fillColor, 0xFF3333);              
			polygon.fillAlpha=isNull(thispolygonStyle.fillAlpha, 1);  //透明度
			polygon.lineColor=isNull(thispolygonStyle.lineColor, 0xFF3333);//0x0000ff;  //线颜色      
			polygon.lineThickness=isNull(thispolygonStyle.lineThickness, 1); //网格线宽 	
			polygon.line=isNull(thispolygonStyle.line, true); //网格线宽 	
			polygon.MaxVisibleZoom=isNull(polygonLegendStyle.maxVisibleZoom,int.MAX_VALUE);
			polygon.MinVisibleZoom=isNull(polygonLegendStyle.minVisibleZoom,1);
			polygon.name=idno;
			polygon.featureName=featureName;
			polygon.updateGraphics();
			polygon.zIndex=zIndex;

			if(isShowTitle){
				_PolyLegendMarkers[idno]=label;
			}
			
			_PolygonMarkers[idno]=polygon;
			_PolygonMarkersNum++;
		}
		
		
		/**清除所有线图对象
		 * 但是线图对象还是缓存起来的
		 */
		public function ClearMarkers():void{
			var polymaker:PolygonMakerExtends;
			for(var key:String in _PolygonMarkers)
			{
				polymaker = _PolygonMarkers[key];
				if(polymaker){
					PolygonLayer.removeMarkerObject(polymaker);
				} 
			}
			var polyLegendmaker:PointMarker;
			for(var key3:String in _PolyLegendMarkers){
				polyLegendmaker = _PolyLegendMarkers[key3];
				if(polyLegendmaker){
					LegendLayer.removeMarkerObject(polyLegendmaker);
				} 
			}
		}
		/**
		 * 远程获取数据
		 * 并绘制图层
		 */ 
		public function initData():void{
			HttpDataHelper.load(polygonUrl, "GET", null, onDataResultPolygon, onfaultResult);
		}
		/**
		 * 解析面图层的数据
		 */ 
		private function onDataResultPolygon(sender:HttpDataLoader, e:Event):void{
			var _sResult:String = sender.data as String;
			
			if(_sResult != null && _sResult.length > 0){
				var _oResult:Array = JSON.deserialize(_sResult) as Array;
				if(_oResult != null){
					_oResult.forEach(function(item:*, index:int, array:Array):void{
						drawPolygon(index,item);
					}, null);
				}
			}
			Resume();
		}
		/**错误处理
		 */ 
		private function onfaultResult(sender:HttpDataLoader,event:ErrorEvent):void
		{
			Alert.show("获取图层数据错误:" + event.text);
		}
		/** 重新显面图对象
		 */ 
		public function Resume():void{
			var polymaker:PolygonMakerExtends;
			for(var key:String in _PolygonMarkers)
			{
				polymaker = _PolygonMarkers[key];
				if(polymaker){
					PolygonLayer.attachMarker(polymaker, polymaker.location);
				} 
			}
			var polyLegendmaker:PointMarker;
			for(var key3:String in _PolyLegendMarkers){
				polyLegendmaker = _PolyLegendMarkers[key3];
				if(polyLegendmaker){
					LegendLayer.attachMarker(polyLegendmaker,polyLegendmaker.location);
				} 
			}
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
		
		
		/*=================根据Data数组，绘制多边形  BY  hxd start 20150630=================*/
		public function drawPolygonByArray(data:Array):void{
			if(data != null){
				data.forEach(function(item:*, index:int, array:Array):void{
					drawPolygon(index,item);
				}, null);
			}
			Resume();
		}
		/*=================根据Data数组，绘制多边形  BY  hxd end 20150630=================*/
	}
}