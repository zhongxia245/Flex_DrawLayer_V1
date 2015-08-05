package strongsoft.eventPanel
{
	import DrawMap.DrawLayerHelper;
	
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import mx.collections.ArrayCollection;
	import mx.collections.Sort;
	import mx.controls.Alert;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.messaging.AbstractConsumer;
	import mx.modules.Module;
	import mx.utils.StringUtil;
	
	import strongsoft.Utility.URLLoaderHelper;
	import strongsoft.commonlib.argextend.EventArgExtend;
	import strongsoft.frameEvents.CommonEvent;
	import strongsoft.frameEvents.EventManage;
	import strongsoft.frameMapTool.MapToolHelper;
	import strongsoft.frameModule.SystemHelper;
	
	import tileMap.Map;
	import tileMap.events.MarkerEvent;
	import tileMap.flex.TweenMapComponent;
	import tileMap.mapproviders.strongsoft.ArcTileLineMapProvider;
	
	import tileMapWidgets.utility.MapManage;
	
	
	/**
	 * TODO:
	 * 下一版本功能:
	 * 	1. 为图层提供默认的鼠标移入移除控件,或者可以传入方法参数   
	 * 
	 * 通用绘制地图 </br>
	 * 功能: </br>
	 * 	1. 根据配置的参数,请求数据,绘制图层,设置点击事件(默认弹窗) </br>
	 *  2. 可以允许多个图层共存 eg: 点面共存,点线共存,线面共存等 </br>
	 *  3. 该类,绘制图层的方法是使用自己封装的类 [后期要改成二部通用的绘制点线面的类库] </br>
	 *  4. 该类,监听一个DataKey的事件 [DataKey 主要 是右侧站点列表数据 ]</br>
	 * ============V1.0 新增功能===========</br>
	 *  5. 该类内置图层管理方法(面图层方法最下面,线图层次之,最上面的是点图层)</br>
	 *  6. 该类提供默认参数配置,如果外部没有传参进来,则使用默认参数配置[但是 type,url 一定需要设置]</br>
	 * 流程</br>
	 * 	1. 站点列表请求数据 --> DataKey--> 通用绘制类监听DataKey发生改变 --> 请求图层数据 --> 图层数据处理(关联列表的数据) --> 绘制图层  --> 设置点击事件   </br>
	 * @author hxd
	 */	
	public class EventPanel_DrawLayer_V1 extends Module
	{
		//版本号
		public static const VERSION:String = "V1.0";
		public static const VERSIONTIME:String = "2015-08-05 09:00";
		
		//固定参数
		public static const FIXED:String="fixed"
		private static const PARAMS:String = "params";
		private static const POLYGONLAYERLEGENGD:String = "PolygonLayerLegengd";  //面图层上文字图例的图层名【面图层=面+文字图层】
		
		/*默认的图层基本配置*/
		private  var _defaultFixedConfig:Object = {
			"layerName": "layerName",
			"dataKey": "dataKey",
			"lon": "LGTD",
			"lat": "LTTD",
			"idno": "STCD",
			"name":"STNM",
			"panelId": "",
			"openPanelId": "",
			"moduleKey": "",
			"isDrawPoint": false,
			"isFilterPoint":true
		};
		/*每个点线面图层的数据配置*/
		private  var _defaultParamConfig:Object = {
			"url": "",
			"type": "point",
			"lon": "LGTD",
			"lat": "LTTD",
			"idno": "STCD",
			"name":"STNM"
		};
		
		/*使用该SWF,在地图上所有图层数组*/
		private var _layerNames:Array = [];
		
		//开始使用该SWF绘制之前的图层数量
		private var _preDraw_LayersCount:Number = MapToolHelper.map.layers.count;
		/*========================================公有函数  START============================================*/
		
		/**
		 * 根据参数，绘制图层 
		 * @param event
		 * @param elementInfo 
		 * @param fixedParam
		 * @param caller
		 *  配置参数EXAMPLE
			fixedParam = {
			"fixed":{"layerName":"layer",   	//图层名称
			"dataKey":"listData",  				//列表数据的DataKey
			"lon":"LGTD",   					//列表经纬度的字段
			"lat":"LTTD",    
			"idno":"STCD",   					//列表数据的唯一标识
			"name":"STNM",                      //列表数据的名称
			"panelId":"paenlId",      			//列表面板ID   (监听模块加载,隐藏等事件)
			"openPanelId":"pnl_popDb",  //站点点击弹窗的面板ID (监听弹窗事件,第一次加载,第二次加载)
			"moduleKey":"popDb",  //站点点击弹窗的模块Key
			"isDrawPoint":true,    //是否用DataKey的值来绘制图层(点线面)
			"isFilterPoint":true   //是否关联DataKey过滤站点
			},
			"params":[
			{"url":"getDBLayerData","type":"point","lon":"LGTD","lat":"LTTD","idno":"STCD"},
			{"url":"getXZHQLayerData","type":"line","lon":"LGTD","lat":"LTTD","idno":"STCD"},
			{"url":"getQLLayerData","type":"polygon","lon":"LGTD","lat":"LTTD","idno":"STCD"}
			]
			};
		 */		
		public function init(event:FlexEvent,elementInfo:Object,fixedParam:Object,caller:Function=null):void{ 
			
			//0. 合并参数
			fixedParam = extendFixedParam(fixedParam);
			
			//1. 必填参数
			var fixed:Object = fixedParam[FIXED];   
			var dataKey:String = fixed["dataKey"].toString();   //获取 右侧列表的Datakey
			
			//2. 模块面板显示隐藏的监听事件【功能：显隐图层】
			addEventListener_layerShowAndHide(fixedParam);
			
			//3. 注册弹窗位置的监听事件【功能：弹窗位置在点位右下角】
			if(fixed["openPanelId"])
				addEventListener_PopLocation(fixed["openPanelId"]);
			
			//4. 监听列表的DataKey,绘制图层
			EventManage.getInstance().add("dataKey_"+dataKey,function(ce:CommonEvent):void{ 
				//4.1 绘制图层【核心】			
				drawLayerOperator(ce.param[0],ce.param[1]);
			},fixedParam);
			
			//5. 存储器已存在Datakey,则手动触发
			if(SystemHelper.dataKey_get(dataKey)!=null){ 
				SystemHelper.listener_dispatch("dataKey_"+dataKey,SystemHelper.dataKey_get(dataKey));
			}
		}
		
		/*========================================私有函数  START============================================*/
		/**
		 * 2. 当模块隐藏或者显示时，图层也随着显示隐藏 
		 * @param panelId 模块面板的ID
		 * @param layerName 图层名
		 * @param type 
		 */		
		private function addEventListener_layerShowAndHide(fixedParam:Object):void{
			var panelId:String = fixedParam[FIXED]["panelId"];
			//模块显示
			SystemHelper.listener_addPanelShow(panelId,function(e:CommonEvent):void{
				layerShowOrHide(e.param[1],true);
			},fixedParam);	
			
			//模块隐藏
			SystemHelper.listener_addPanelHide(panelId,function(e:CommonEvent):void{
				layerShowOrHide(e.param[1],false);
			},fixedParam);	
		}
		
		/**
		 * 2.1 显示或者隐藏图层 
		 * @param fixedParam 参数
		 * @param isVisible  显示   OR 隐藏
		 */		 
		private function layerShowOrHide(fixedParam:Object,isVisible:Boolean=false):void{
			var layerManage:MapManage = new MapManage(MapToolHelper.map);
			
			var layerName:String = fixedParam[FIXED]["layerName"];
			var txtLayerName:String = POLYGONLAYERLEGENGD+layerName;   	//面图层 上文字图层的图层名
			
			if(layerManage.getLayerByName(layerName)!=null)layerManage.getLayerByName(layerName).visible = isVisible;
			
			for(var index:Object in fixedParam[PARAMS]){
				if(layerManage.getLayerByName(layerName+index)!=null)layerManage.getLayerByName(layerName+index).visible = isVisible;
				if(layerManage.getLayerByName(txtLayerName+index)!=null)layerManage.getLayerByName(txtLayerName+index).visible = isVisible;
			}
		}
		
		/**
		 * 3. 注册弹窗位置的监听 
		 * @param openPanelId 弹窗面板ID
		 */		
		private function addEventListener_PopLocation(openPanelId:String):void{
			SystemHelper.listener_addPanelLoaded(openPanelId,function(e:CommonEvent):void{
				e.param.setStyle("left",SystemHelper.memory_get("point").x);
				e.param.setStyle("top",SystemHelper.memory_get("point").y); 
			},null);
			SystemHelper.listener_addPanelShow(openPanelId,function(e:CommonEvent):void{
				e.param[0].setStyle("left",SystemHelper.memory_get("point").x);
				e.param[0].setStyle("top",SystemHelper.memory_get("point").y);
			},null);
		}
		
		/**
		 * 4.1  绘制图层【核心】	
		 * @param dataKeyData
		 * @param fixedParam
		 * 
		 */		
		private function drawLayerOperator(dataKeyData:Array,fixedParam:Object):void{
			
			//已经请求结束的URL个数
			var alreadyRequestCount:Number = 0;
			
			var params:Object = fixedParam[PARAMS];
			params = paramsSort(params);
			
			//4.1.1 是否用DataKey的数据绘制点图层
			if(fixedParam[FIXED]["isDrawPoint"]){
				dataKeyData = replaceDataKeyLonLat(dataKeyData,fixedParam[FIXED]);
				drawPointLayer(dataKeyData,fixedParam[FIXED].layerName,fixedParam[FIXED].moduleKey,fixedParam[FIXED].layerName);
			}
			
			//绘制Params里面配置的图层
			for(var index:Object in params){
				var url:String = SystemHelper.url_get(params[index].url);
				//4.1.2 请求图层数据
				URLLoaderHelper.post(url,null,EventArgExtend.create(function(ev:Event,... arg):void{
					var result:String = ev.target.data as String;
					var urlData:Array = JSON.deserialize(result) as Array;
					
					urlData = dataHandler(urlData, dataKeyData,params[arg[0]].type, fixedParam,params[arg[0]]["idno"],params[arg[0]]["lon"],params[arg[0]]["lat"]);
					
					//4.1.2.1 根据Type类型，绘制图层
					drawLayerByType(params[arg[0]].type,urlData,fixedParam[FIXED].layerName+arg[0], fixedParam[FIXED].moduleKey,fixedParam[FIXED].layerName);
					
					/*
						2015-08-04 16:25 by hxd
						图层管理  (作用: 面<线<点    面图层最下面,线图层次之,点在最上面)
					*/
					_layerNames.push({"type":params[arg[0]].type,"layerName":fixedParam[FIXED].layerName+arg[0]});
					alreadyRequestCount++;
					if(alreadyRequestCount==params.length){//表示所有的图层数据,已经请求结束
						layerManageHandler(fixedParam[FIXED].layerName);
					}
				},index));
			}
		}
		
		/*==============================绘制图层方法  START=================================*/
		/**
		 * 根据类型，绘制图层 
		 * @param type 图层类型
		 * @param url  图层数据请求地址
		 * @param layerName  图层名
		 * @param map  地图对象
		 * @param moduleKey 弹窗的模块Keyfb
		 */		
		private function drawLayerByType(type:String,data:Array,layerName:String,moduleKey:String,clickDataKey:String):void{
			switch(type){
				case "point":  //根据URL请求回的数据，绘制点图层
					drawPointLayer(data,layerName,moduleKey,clickDataKey); 
					break;
				case "line":  //绘制线图层
					drawLineLayer(data,layerName,moduleKey,clickDataKey);
					break;
				case "polygon": //绘制线面图层
					drawPolygonLayer(data,layerName,moduleKey,clickDataKey);
					break;
				default:
					Alert.show("type类型必须为以下几种：point 点图层（DataKey） / line 线图层 / polygon 面图层 ","提示");
					break;
			}
		}
		
		/*===============================点图层 START=====================================*/
		/**
		 * 绘制点图层[从URL获取数据]
		 * @param url
		 */		
		private function drawPointLayer(data:Array,layerName:String,moduleKey:String,clickDataKey:String):void{
			DrawLayerHelper.drawPoint(layerName,MapToolHelper.map,data,function(e:MarkerEvent):void{
				pointClickHandler(layerName,moduleKey,e,clickDataKey);
			});
		}
		
		/**
		 * 线图层点击事件 [弹窗，保存站点编号，站点名称,保存在【图层名+ClickData】的存储器Key中]
		 * @param layerName 
		 * @param moduleKey
		 * @param e
		 */		
		private function pointClickHandler(layerName:String,moduleKey:String,e:MarkerEvent,clickDatakey:String):void{
			var point:Point =  MapToolHelper.map.map.locationPoint(e.location);
			SystemHelper.memory_set("point",point);
			
			var stcd:String ="";
			var stnm:String = "";
			//点击的是图源
			if(e["marker"]["parent"].hasOwnProperty("id")&&e["marker"]["parent"]["id"]!=null)
			{
				stcd= e["marker"]["parent"]["id"];
				stnm = e["marker"][["parent"]].labels[0].text;
			}
				//点击的是站点名
			else{ 
				stcd= e["marker"]["parent"]["parent"]["id"];
				stnm = e["marker"]["text"];
			}
			//把经纬度
			SystemHelper.dataKey_set(clickDatakey,{"STNM":stnm,"STCD":stcd,"Marker":e["marker"]});
			SystemHelper.hideModule(moduleKey);
			SystemHelper.loadModule(moduleKey);
		}
		
		
		
		
		
		/*===============================线图层 START=====================================*/
		/**
		 * 绘制线图层
		 * @param url
		 */		
		private function drawLineLayer(data:Array,layerName:String,moduleKey:String,clickDataKey:String):void{
			DrawLayerHelper.drawLineByArray(layerName,MapToolHelper.map,data,function(e:MouseEvent):void{
				lineAndPolygonClickHandler(layerName,moduleKey,e,clickDataKey);
			});
		}
		
		
		/*===============================面图层 START=====================================*/
		/**
		 * 绘制面图层
		 * @param url
		 */		
		private function drawPolygonLayer(data:Array,layerName:String,moduleKey:String,clickDataKey:String):void{
			DrawLayerHelper.drawPolygonByArray(layerName,MapToolHelper.map,data,function(e:MouseEvent):void{
				lineAndPolygonClickHandler(layerName,moduleKey,e,clickDataKey);
			});
		}
		
		/**
		 * 线，面图层点击事件处理 
		 * @param layerName
		 * @param moduleKey
		 * @param e
		 */		
		private function lineAndPolygonClickHandler(layerName:String,moduleKey:String,e:MouseEvent,clickDatakey:String):void{
			var stnm:String = "";
			var stcd:String = "";
			
			if(e.target.hasOwnProperty("featureName")){  //点击的是图元
				stnm = e.target.featureName+"";
				stcd = e.target.name+"";
			}
			else if(e.target.hasOwnProperty("text"))   //点击图元上的文字
			{
				stcd = e.target.parent.id;
				stnm = e.target.text;
			}else if(e.target is Loader)   //点击图元上已经预警的图片
			{
				stcd = e.target.parent.id;
				stnm = e.target.parent.legendText;
			}
			SystemHelper.dataKey_set(clickDatakey,{"STNM":stnm,"STCD":stcd,"Target":e.target});
			SystemHelper.hideModule(moduleKey);
			SystemHelper.loadModule(moduleKey);
		}
		
		/*==============================绘制图层方法  END=================================*/
		
		
		/*=================================数据处理  START===========================================*/
		/**
		 * [针对点图层,如果是线面图层,需要绘制出图层,再获取图层重点点,在关联列表数据处理.]
		 * 4.1.2 数据处理层，请求回的数据，到绘制图层的时候，中间对数据进行一个处理 
		 * @param data  URL请求回的数据
		 * @param dataKeyData  存在DataKey里面的数据
		 * @return 匹配出列表有的站点数据
		 */		
		private function dataHandler(urlData:Array,dataKeyData:Array,type:String,fixedParam:Object,idno:String,lon:String,lat:String):Array{
			
			//获取两个数组 关联的字段
			var dataKeyidno:String = fixedParam.hasOwnProperty("idno")?fixedParam["idno"]+"":"STCD";  //右侧列表与URL读取数据的关联字段
			
			//获取两个数组中，经纬度所存的字段
			var dataKeyLon:String = fixedParam[FIXED].hasOwnProperty("lon")?fixedParam[FIXED]["lon"]+"":"LGTD";  //Datakey中所需的Datakey字段
			var dataKeyLat:String = fixedParam[FIXED].hasOwnProperty("lat")?fixedParam[FIXED]["lat"]+"":"LTTD"; 
			
			var dataNew:Array = new Array(); 
			if(type == "point"){
				for(var index:Object in urlData){
					for(var j:Object in dataKeyData){
						if(StringUtil.trim(urlData[index][idno]+"")==StringUtil.trim(dataKeyData[j][dataKeyidno]+""))
						{
							var item:Object = urlData[index];
							//为DataKey的数组添加经纬度信息
							item[dataKeyLon] =urlData[index][lon];
							item[dataKeyLat] = urlData[index][lat];
							dataNew.push(item);
						}
					}
				}
				return dataNew;
			}	
			else if (type == "polygon" ||type == "line"){  //过滤面图层数据,线图层数据
				//TODO:目前不做处理(等绘制图层统一之后,在考虑是否要处理)   20150804 by  hxd
				return urlData;
			}
			return urlData;
		}
		
		/**
		 * 设置DataKey的经纬度字段,唯一标识字段 (eg:DataKey中,经纬度为lon,lat   可是绘制要求为LGTD,LGGD,所以需要做一个转换) 
		 * @param dataKeyData
		 * @param fixConfig
		 * @return 
		 */		
		private function replaceDataKeyLonLat(dataKeyData:Array,fixConfig:Object):Array{
			var dataKeyData_New:Array = new Array();
			if(dataKeyData[0].hasOwnProperty("STCD")&&dataKeyData[0].hasOwnProperty("STNM")&&dataKeyData[0].hasOwnProperty("LGTD")&&dataKeyData[0].hasOwnProperty("LTTD")){
				return dataKeyData;
			}else {
				for(var i:Number=0;i<dataKeyData.length;i++){
					var item:Object = new Object();
					item = dataKeyData[i];
					var lon:String = fixConfig["lon"]!=null?fixConfig["lon"]:"LGTD";
					var lat:String = fixConfig["lat"]!=null?fixConfig["lat"]:"LTTD";
					var idno:String = fixConfig["idno"]!=null?fixConfig["idno"]:"STCD";
					var stnm:String = fixConfig["name"]!=null?fixConfig["name"]:"STNM";
					item["LGTD"] = dataKeyData[i][lon];
					item["LTTD"] = dataKeyData[i][lat];
					item["STCD"] = dataKeyData[i][idno];
					item["STNM"] = dataKeyData[i][stnm];
					dataKeyData_New.push(item);
				}
				return dataKeyData_New;
			}
		}
		
		/**
		 * 图层参数处理(图层类型,图层数据URL,图层经纬度字段参数)
		 * 图层按照  面 < 线 < 点 进行排序(面在最下面,然后线在中间,点在上面)
		 * */
		private function paramsSort(params:Object):Array{
			var param_new:ArrayCollection = new ArrayCollection();
			//var sortValue:Array =  ["point","line","polygon"]; 
			var sortValue:Array =  ["polygon","line","point"]; 
			for(var index:* in sortValue){
				for(var i:* in params){
					if(params[i]["type"]==sortValue[index]){
						if(!param_new.contains(params[i]))
							param_new.addItem(params[i]);
					}
				}
			}
			return param_new.toArray();
		}
		/*=================================数据处理  END===========================================*/
		
		/*=================================图层管理事件  START===========================================*/
		/**
		 * 
		 * 2015-08-04 16:25 by hxd		
		 * 图层管理  (作用: 面<线<点    面图层最下面,线图层次之,点在最上面)
		 * @param fixedParam 绘制图层参数配置
		 * @param layerCount 没绘制前,图层的数量
		 */		
		private function layerManageHandler(layerName:String):void{
			var layerName:String = layerName;
			var layers:MapLayerManager = MapToolHelper.map.layers;
			
			/*地图对象中,除了图层还有其他对象,计算出图层开始的下标
			(图层开始下标 = 地图对象子控件书-图层个数-进度条,地图工具栏)*/
			var layerStartIndex:Number = MapToolHelper.map.numChildren-layers.count-2;
			
			//获取图层数据配置  ,并按照 ( point>line>polygon 进行排序)
			_layerNames = paramsSort(_layerNames);
			
			//设置图层的位置(上一层,还是下一层)
			var index:Number = 0;
			for(var i:Number = 0; i < _layerNames.length; i++){
				var layerName1:String = _layerNames[i]["layerName"];
				var layerType:String = _layerNames[i]["type"];
				if(layers.getLayerByName(layerName1))
					MapToolHelper.map.setChildIndex(layers.getLayerByName(layerName1),layerStartIndex+_preDraw_LayersCount+index++);
				
				if(layerType=="polygon"){ //图层为面图层(面图层有liange)
					if(layers.getLayerByName(POLYGONLAYERLEGENGD+layerName1))
						MapToolHelper.map.setChildIndex(layers.getLayerByName(POLYGONLAYERLEGENGD+layerName1),layerStartIndex+_preDraw_LayersCount+index++);
				}
			}
			//使用DataKey数据,绘制的图层,放到最顶层
			if(layers.hasOwnProperty(layerName)){
				layers.getLayerByName(layerName).getChildAt(layers.count-1);
			}
		}
		
		/*=================================数据处理  END===========================================*/
		
		/*==========================通用方法 START  2015-08-04 16:00================================*/
		/**
		 * 合并参数 
		 * eg: 默认参数 {"name":"123","age":18}   参数:{"age":15,"score":88}
		 * 合并后 {}
		 * @param defaultParam 默认参数
		 * @param param 参数
		 * @return 合并后的参数
		 */		
		private function extend(defaultParam:Object,param:Object):Object{
			var param_new:Object = new Object();
			
			for(var key:* in defaultParam)
			{
				param_new[key] = defaultParam[key];
			}
			
			for(var key1:* in param)
			{
				param_new[key1] = param[key1];
			}
			
			return param_new;
		}
		
		/**
		 * 合并 fixedParam 参数(把手动配置的参数,和默认参数合并起来)
		 * @return 合并后的对象
		 */		
		private function extendFixedParam(fixedParam:Object):Object{
			if(fixedParam.hasOwnProperty("fixed"))
				fixedParam["fixed"] = extend(_defaultFixedConfig,fixedParam["fixed"]);
			if(fixedParam.hasOwnProperty("params")){
				for(var i:Number=0; i < fixedParam["params"].length;i++)
					fixedParam["params"][i] = extend(_defaultParamConfig,fixedParam["params"][i]);
			}
			return fixedParam;
		}
		/*==========================通用方法 END  2015-08-04 16:00================================*/
	}
}