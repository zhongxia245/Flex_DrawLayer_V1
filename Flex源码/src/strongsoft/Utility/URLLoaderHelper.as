package strongsoft.Utility 
{
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	
	import mx.controls.Alert;
	
	import strongsoft.frameMemoryData.Data;
	
	public class URLLoaderHelper
	{
		public function URLLoaderHelper()
		{
		}
		/**
		 * 请求服务端接口（POST方式） 
		 * @param url  请求地址
		 * @param data  传输到服务端的数据
		 * @param callback 请求成功回调函数
		 * @param error 请求出错的回调函数  默认为Null 
		 * @param isPostJsonObj 请求出错的回调函数  默认为false,如果为true,Data必须为JSON格式的字符串
		 * @param isAddRandomParam 是否在URL地址上添加一个随机参数，防止缓存 r=5656546635
		 */		
		public static function post(url:String,data:Object,success:Function,error:Function=null,isPostJsonObj:Boolean=false,isAddRandomParam:Boolean=false):void{
			var urlReq:URLRequest = new URLRequest();
			//传递一个随机参数
			if(isAddRandomParam){
				if(url.indexOf('?')!=-1){
					url+= "&r="+ new Date().getTime();
				}else{
					url+= "?r="+ new Date().getTime();
				}
			}
			
			urlReq.url = url;
			urlReq.method = URLRequestMethod.POST;
			
			//POST传递的参数
			var param:URLVariables = new URLVariables();
			if(data!=null){
				if(!isPostJsonObj){  //是否把整个JSON字符串，传递过去
					for(var key:* in data){
						param[key] = data[key];
					}
					urlReq.data = param;
				}else{
					param.data = data;
					urlReq.data = param;
				}
			}
			
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.load(urlReq);
			
			urlLoader.addEventListener(Event.COMPLETE,success);
			
			if(error!=null){
				urlLoader.addEventListener(IOErrorEvent.IO_ERROR,error);
			}else{
				urlLoader.addEventListener(IOErrorEvent.IO_ERROR,function(e:ErrorEvent):void{
					Alert.show("请求地址："+url+"==>出现异常！"+e.text);
				});
			}
		}
	}
}