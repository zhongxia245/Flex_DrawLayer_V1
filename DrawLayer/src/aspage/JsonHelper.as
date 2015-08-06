/*
* 创建：trg
* 时间：20101101
* 功能：合并两个 json 对象。地图项目中copy过来的
*/
package aspage 
{
	public class JsonHelper
	{
		public static function combin(...param:*):*
		{
			if (param.length == 0)
			{
				return null;
			}
			if (param.length == 1)
			{
				return param[0];
			}
			var target:* = { };
			var options:*;
			var src:*;
			var copy:*
			for (var i:int = 0; i < param.length; i++ )
			{
				if ( (options = param[ i ]) != null )
				{
					for (var name:String in options )
					{
						src = target[name];
						copy = options[ name ];
						
						if ( target === copy )
							continue;
						
						if ( copy !== undefined )
						{
							if(!(copy is Array) && (typeof copy) == "object")
							{
								target[ name ] = JsonHelper.combin(src, copy);
							}
							else
							{
								target[ name ] = copy;
							}
						}
					}
				}
			}
			return target;
		}
	}
}