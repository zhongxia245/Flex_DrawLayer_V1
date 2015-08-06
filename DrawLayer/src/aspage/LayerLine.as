/**
 *修改标志： MapLayerConfigMapid属性改为Public，使得可以动态的更改读取的配置节点的数据
 * 
 */
package aspage 
{
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.controls.Alert;
	
	import tileMap.TweenMap;
	import tileMap.flex.TweenMapComponent;
	import tileMap.geo.*;
	import tileMap.overlays.PolygonClip;
	
	import tileMapWidgets.data.HttpDataLoader;
	import tileMapWidgets.data.JSON;
	
	/**
	 * tyh20120607
	 * 封装线图层的相关操作，主要包括产生线图并绘制对象，包装点击、悬停事件
	 */ 
	public class LayerLine
	{
		
		private var m_oMap:TweenMapComponent;//地图组建
		private var Layer:PolygonClip;//地图缩放而缩放的标记对象容器，通常用于管理线、面对象，例如向地图添加某个地区的边界线，或叠加云图等。
		private var _PolyLineMarkers:*={};//缓存线图层对象
		public var lineStyle:*={styles:{"lineColor":"0x2C24E0","lineThickness":"3","lineAlpha":"0.7","minVisibleZoom":"1","maxVisibleZoom":"18"}};//线图层的默认的样式
		
		//MapLayerConfig中配置的Id
		public var MapLayerConfigMapid:String="";
		public var polyLineUrl:String="MapLineDataProvider.ashx";
		
		/**数据是否成功加载的标志
		 */
		public var HasLoadData:Boolean=false;
		private var _useHandCursor:Boolean=false;
		private var _clickfn:Function=null;
		private var _mouseOverfn:Function=null;
		private var _mouseOutfn:Function=null;
		private var loader:HttpDataLoader=null;
		
		/**
		 *设置鼠标手型显示 
		 */
		public function set useHandCursor(value:Boolean):void
		{
			_useHandCursor = value;
			var polyLinemaker:PolyLineMakerExtends;
			for(var key2:String in _PolyLineMarkers){
				polyLinemaker = _PolyLineMarkers[key2];
				if(polyLinemaker){
					polyLinemaker.useHandCursor=value;
					polyLinemaker.buttonMode=value;
				} 
			}
		}
		/**设置面涂层面对象的事件的处理函数，设置为null将移除原有的侦听
		 * @param value 方法签名 function(e:MouseEvent):void
		 *{
		 * //获取相关数据信息
		 * e.currentTarget  as PolylineMarker;
		 *}
		 */ 
		public function set mouseOutfn(value:Function):void
		{
			var polyLinemaker:PolyLineMakerExtends;
			for(var key2:String in _PolyLineMarkers){
				polyLinemaker = _PolyLineMarkers[key2];
				if(polyLinemaker){
					if(_mouseOutfn!=null){
						polyLinemaker.removeEventListener(MouseEvent.MOUSE_OUT,_mouseOutfn);
					}
					if(value!=null){
						polyLinemaker.addEventListener(MouseEvent.MOUSE_OUT,value);
					}
				} 
			}
			_mouseOutfn = value;
		}

		/**设置面涂层面对象的事件的处理函数，设置为null将移除原有的侦听
		 * @param value 方法签名 function(e:MouseEvent):void
		 *{
		 * //获取相关数据信息
		 * e.currentTarget  as PolyLineMakerExtends;
		 *}
		 */ 
		public function set mouseOverfn(value:Function):void
		{
			var polyLinemaker:PolyLineMakerExtends;
			for(var key2:String in _PolyLineMarkers){
				polyLinemaker = _PolyLineMarkers[key2];
				if(polyLinemaker){
					if(_mouseOverfn!=null){
						polyLinemaker.removeEventListener(MouseEvent.MOUSE_OVER,_mouseOverfn);
					}
					if(value!=null){
						polyLinemaker.addEventListener(MouseEvent.MOUSE_OVER,value);
					}
				} 
			}
			_mouseOverfn = value;
		}
		/**设置面涂层面对象的事件的处理函数，设置为null将移除原有的侦听
		 * @param value 方法签名 function(e:MouseEvent):void
		 *{
		 * //获取相关数据信息
		 * e.currentTarget  as PolyLineMakerExtends;
		 *}
		 */ 
		public function set clickfn(value:Function):void
		{
			var polyLinemaker:PolyLineMakerExtends;
			for(var key2:String in _PolyLineMarkers){
				polyLinemaker = _PolyLineMarkers[key2];
				if(polyLinemaker){
					if(_clickfn!=null){
						polyLinemaker.removeEventListener(MouseEvent.CLICK,_clickfn);
					}
					if(value!=null){
						polyLinemaker.addEventListener(MouseEvent.CLICK,value);
					}
				} 
			}
			_clickfn = value;
		}
		
		/**
		 * 画线类
		 * @param 地图组建对象
		 * @param 图层
		 */ 
		public function LayerLine(map:TweenMapComponent,MapLayerConfigMapid:String,Clip:PolygonClip)
		{
			this.m_oMap=map;
			this.Layer=Clip;
			this.MapLayerConfigMapid=MapLayerConfigMapid;
			loader=new HttpDataLoader();
		}
		
		/**
		 * 获取线对象缓存
		 * 以键值存储PolylineMarker对象
		 * 获取每个对象
		 * var polyLinemaker:PolyLineMakerExtends;
		 *	for(var key2:String in _PolyLineMarkers){
		 *		polyLinemaker = _PolyLineMarkers[key2];
		 */ 
		public function get PolyLineMarkers():*
		{
			return _PolyLineMarkers;
		}
		
		private function set PolyLineMarkers(value:*):void
		{
			_PolyLineMarkers = value;
		}
		
		public function initData():void{
			if(MapLayerConfigMapid!=""){
				loader.load(polyLineUrl , "GET", null, onDataResultPolyLine, onfaultResult);
			}
			else{
				Alert.show("图层ID值未配置");
			}
		}
		/**
		 * 解析线图层的数据
		 * 
		 * 
		 */ 
		private function onDataResultPolyLine(sender:HttpDataLoader, e:Event):void{
			var _sResult:String = sender.data as String;
			if(_sResult != null && _sResult.length > 0){
				var _oResult:Array = JSON.deserialize(_sResult) as Array;
				if(_oResult != null){
					//遍历每一个小流域
					_oResult.forEach(function(item:*, index:int, array:Array):void{					
						drawPolyLine(item);
					}, null);
				}
				HasLoadData=true;
			}
			Resume();
		}
		/**
		 * 错误处理	
		 */ 
		private function onfaultResult(sender:HttpDataLoader,event:ErrorEvent):void
		{
			Alert.show("获取图层数据错误:" + event.text);
		}
		/**
		 * 画线图
		 * 
		 */ 
		public function drawPolyLine(item:*):void
		{
			var thislinestyle:*=JsonHelper.combin(lineStyle.styles, item.styles);
			var data:*=item.data;
			var IDNO:String=item.idno;
			
			/*=======================START 20150806 by hxd============*/
			/*处理一个站点有多条线,或者只有一条线的处理*/
			if(data[0] is Array){
			}else{
				data = [data];
			}
			/*==================END 20150806 by hxd===============*/
			//遍历数据中是否存在多个线图层数据
			for(var i:int=0;i<data.length;i++){
				var arr:Array=new Array();
				for(var j:int = 0;j<data[i].length;j++)
				{
					arr.push(new Location(data[i][j].x,data[i][j].y));
				}
				//绘制线图层
				drawLine(m_oMap.map,arr,IDNO+i,item,thislinestyle);
			}
		}
		
		/**
		 * 绘制线图层 [drawPolyLine 方法调用]
		 * @param map
		 * @param data
		 */		
		private function drawLine(map:TweenMap,data:Array,IDNO:String,item:Object,thislinestyle:Object):void{
			
			var line:PolyLineMakerExtends = new PolyLineMakerExtends(map, data);
			
			if(_clickfn!=null)
				line.addEventListener(MouseEvent.CLICK,_clickfn);
			if(_mouseOverfn!=null)
				line.addEventListener(MouseEvent.MOUSE_OVER,_mouseOverfn);
			if(_mouseOutfn!=null){
				line.addEventListener(MouseEvent.MOUSE_OUT,_mouseOutfn);
			}
			line.useHandCursor=_useHandCursor;
			line.buttonMode=_useHandCursor;
			line.name =IDNO;
			line.featureName=isNull(item.featureName,isNull(item.attributes.NAME,""));
			line.lineColor = isNull(thislinestyle.lineColor, 0xFF3333);
			line.lineThickness = isNull(thislinestyle.lineThickness, 1);
			line.lineAlpha=isNull(thislinestyle.lineAlpha, 1);
			
			if(!isNaN(thislinestyle.minVisibleZoom)){
				line.minVisibleZoom = thislinestyle.minVisibleZoom;
			}
			if(!isNaN(thislinestyle.maxVisibleZoom)){
				line.maxVisibleZoom = thislinestyle.maxVisibleZoom;
			}
			_PolyLineMarkers[IDNO]=line;
		}
		
		
		/**清除所有线图对象
		 */
		public function ClearMarkers():void{
			var polyLinemaker:PolyLineMakerExtends;
			for(var key2:String in _PolyLineMarkers){
				polyLinemaker = _PolyLineMarkers[key2];
				if(polyLinemaker){
					Layer.removeMarkerObject(polyLinemaker);
				} 
			}
		}
		/** 重新显示线图对象
		 */ 
		public function Resume():void{
			var polyLinemaker:PolyLineMakerExtends;
			for(var key2:String in _PolyLineMarkers){
				polyLinemaker = _PolyLineMarkers[key2];
				if(polyLinemaker){
					Layer.attachMarker(polyLinemaker,polyLinemaker.location);
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
		
		/*===================根据数据绘制线图层  by  hxd  start  20150630============================*/
		public function drawLineByArray(data:Array):void{
			if(data != null){
				//遍历每一个小流域
				data.forEach(function(item:*, index:int, array:Array):void{					
					drawPolyLine(item);
				}, null);
			}
			HasLoadData=true;
			Resume();
		}
		/*----------------------根据数据绘制线图层     by  hxd  end  20150630-----------------------*/
	}
}