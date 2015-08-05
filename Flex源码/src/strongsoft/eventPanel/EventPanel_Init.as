package strongsoft.eventPanel
{
	import flash.events.MouseEvent;
	
	import mx.controls.Alert;
	import mx.modules.Module;
	
	import strongsoft.frameMapTool.MapToolHelper;
	import strongsoft.frameModule.SystemHelper;
	
	public class EventPanel_Init extends Module
	{
		public function lbClick(e:MouseEvent):void{
			var config:Object = e.target.data;
			var moduleKeys:Array = ["DrawPointByDatakey","DrawPointByURL","DrawLine","DrawPolygon","DrawPL","DrawPP","DrawPLP"];
			
//			//清除图层
//			while(MapToolHelper.map.layers.count!=0){
//				var layerName:String= MapToolHelper.map.layers.getLayer(0).name;
//				MapToolHelper.map.layers.remove(layerName);
//			}
			
			//隐藏图层
			for(var i:Number = 0; i<moduleKeys.length;i++)
			{
				SystemHelper.hideModule(moduleKeys[i]);
			}
			
			SystemHelper.loadModule(config["moduleKey"]);
		}
	}
} 