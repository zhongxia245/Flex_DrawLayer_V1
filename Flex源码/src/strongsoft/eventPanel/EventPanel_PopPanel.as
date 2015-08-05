package strongsoft.eventPanel
{
	import flash.events.Event;
	
	import mx.controls.Alert;
	import mx.events.FlexEvent;
	import mx.modules.Module;
	
	import strongsoft.Utility.URLLoaderHelper;
	import strongsoft.frameEvents.CommonEvent;
	import strongsoft.frameModule.SystemHelper;
	
	public class EventPanel_PopPanel extends Module
	{
		/**
		 * 弹窗数据初始化 [单条数据表格展示]
		 * @param event
		 * @param elementInfo
		 * @param fixedParam
		 * @param caller
		 */		
		public function popDataInit(event:FlexEvent,elementInfo:Object,fixedParam:Object,caller:Function=null):void{
			//1. 注册窗体第一次打开，第二次打开的监听事件
			initDataHandler(elementInfo,fixedParam);
			
			SystemHelper.listener_addPanelShow(fixedParam["panelId"],function(e:CommonEvent):void{
				initDataHandler(e.param[1].elementInfo,e.param[1].fixedParam)
			},{"elementInfo":elementInfo,"fixedParam":fixedParam});
		}  
		
		/**
		 * 弹窗时，数据加载 
		 * @param e 
		 */		
		private function initDataHandler(elementInfo:Object,fixedParam:Object):void{
			//获取站点编号,站点名称
			var param:Object = SystemHelper.dataKey_get(fixedParam["clickPointData"]);
			//获取图层DataKey的数据
			var layerDatas:Object = SystemHelper.dataKey_get(fixedParam["layerDataKey"]);
			var data:Object;
			for(var item:* in layerDatas){
				if(layerDatas[item]["STCD"]==param["STCD"]){
					data = layerDatas[item];
					break;
				}
			}
			data["STNM"] = param["STNM"];
			SystemHelper.dataKey_set(fixedParam["listDataKey"],data);
		}
		
		
		
	}
}