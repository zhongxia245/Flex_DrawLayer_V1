package aspage
{
	/**
	 * 
	 * @author 陈琳
	 * 
	 */	
	public class GaussKruger
	{
		public function GaussKruger()
		{
		}
		/**
		 * WGS-84转换参数
		 */			
		public static const wgs84:Object={"a" : 6378137,	"f" : 298.257223563	};
		
		/**
		 * 西安80转换参数
		 */		
		public static const c80:Object={"a" : 6378140,	"f" : 298.257 };
		
		/**
		 * 北京54转换参数
		 */		
		public static const bj54:Object={"a" : 6378245,	"f" : 298.3 };
		//1975年国际椭球体、西安80坐标系:长半轴：a = 6378140;  短半轴：b = 6356755.2881575287; c = 6399596.6519880105 扁率倒数：f = 298.257; 第一偏心率：e2 = 0.006694384999588; 第二偏心率：e12 = 0.006739501819473;
		//WGS-84椭球体：长半轴：a = 6378137;  短半轴：b = 6356752.3142; c = 6399593.6258 扁率倒数：f = 298.257223563; 第一偏心率：e2 = 0.0066943799013; 第二偏心率：e12 = 0.00673949674227;
		//克拉索夫斯基椭球体、北京54坐标系：长半轴：a = 6378245;  短半轴：b = 6356863.0187730473; c = 6399698.9017827110 扁率倒数：f = 298.3; 第一偏心率：e2 = 0.006693421622966; 第二偏心率：e12 = 0.006738525414683;
		
		/**
		 * 大地坐标转换到平面坐标（适用WGS-84坐标系）
		 * @param lon 经度
		 * @param lat 纬度
		 * @param centerLon 中央经线
		 * @param xOffset 偏移值，默认值500000m
		 * @param yOffset 偏移值，默认值0m
		 * @return 平面坐标数组，[x,y]
		 */
		public static function lonLat_xy_wgs84(lon:Number, lat:Number, centerLon:Number,xOffset:Number=500000,yOffset:Number=0):Array{
			return lonLat_xy(lon,lat,wgs84.a,wgs84.f,centerLon,xOffset,yOffset);
		}
		/**
		 * 大地坐标转换到平面坐标（适用西安80坐标系）
		 * @param lon 经度
		 * @param lat 纬度
		 * @param centerLon 中央经线
		 * @param xOffset 偏移值，默认值500000m
		 * @param yOffset 偏移值，默认值0m
		 * @return 平面坐标数组，[x,y]
		 */
		public static function lonLat_xy_c80(lon:Number, lat:Number, centerLon:Number,xOffset:Number=500000,yOffset:Number=0):Array{
			return lonLat_xy(lon,lat,c80.a,c80.f,centerLon,xOffset,yOffset);
		}
		/**
		 * 大地坐标转换到平面坐标（适用北京54坐标系）
		 * @param lon 经度
		 * @param lat 纬度
		 * @param centerLon 中央经线
		 * @param xOffset 偏移值，默认值500000m
		 * @param yOffset 偏移值，默认值0m
		 * @return 平面坐标数组，[x,y]
		 */
		public static function lonLat_xy_bj54(lon:Number, lat:Number, centerLon:Number,xOffset:Number=500000,yOffset:Number=0):Array{
			return lonLat_xy(lon,lat,bj54.a,bj54.f,centerLon,xOffset,yOffset);
		}
		/**
		 * 大地坐标转换到平面坐标
		 * @param lon 经度
		 * @param lat 纬度
		 * @param a 参考椭球长半轴
		 * @param f 参考椭球扁率倒数
		 * @param centerLon 中央经线
		 * @param xOffset 偏移值，默认值500000m
		 * @param yOffset 偏移值，默认值0m
		 * @return 平面坐标数组，[x,y]
		 */
		public static function lonLat_xy(lon:Number, lat:Number, a:Number, f:Number, centerLon:Number,xOffset:Number=500000,yOffset:Number=0):Array{
			lon = lon - centerLon;
			var arr:Array = new Array();
			var x:Number = 0; //平面横轴
			var y:Number = 0; //平面纵轴
			var ee:Number = (2 * f - 1) / f / f;       //第一偏心率的平方
			var ee2:Number = ee / (1 - ee);            //第二偏心率的平方
			var rB:Number, tB:Number, m:Number;
			rB = lat * Math.PI / 180;
			tB = Math.tan(rB);
			m = Math.cos(rB) * lon * Math.PI / 180;
			var N:Number = a / Math.sqrt(1 - ee * Math.sin(rB) * Math.sin(rB));
			var it2:Number = ee2 * Math.pow(Math.cos(rB), 2);
			y = m * m / 2 + (5 - tB * tB + 9 * it2 + 4 * it2 * it2) * Math.pow(m, 4) / 24 + (61 - 58 * tB * tB + Math.pow(tB, 4)) * Math.pow(m, 6) / 720;
			y = meridianLength(lat, a, f) + N * tB * y;
			x = N * (m + (1 - tB * tB + it2) * Math.pow(m, 3) / 6 + (5 - 18 * tB * tB + Math.pow(tB, 4) + 14 * it2 - 58 * tB * tB * it2) * Math.pow(m, 5) / 120);
			arr[0] = (x + xOffset).toFixed(5);
			arr[1] = (y + yOffset).toFixed(5);
			
			return arr;
		}
		
		
		/**
		 * 平面坐标转换到大地坐标（适用WGS-84坐标系）
		 * @param x X
		 * @param y Y
		 * @param centerLon 中央经线
		 * @param xOffset 偏移值，默认值500000m
		 * @param yOffset 偏移值，默认值0m
		 * @return 大地坐标数组，[lon,lat]
		 */
		public static function xy_LonLat_wgs84(x:Number, y:Number, centerLon:Number,xOffset:Number=500000,yOffset:Number=0):Array{
			return xy_LonLat(x,y,wgs84.a,wgs84.f,centerLon,xOffset,yOffset);
		}
		
		/**
		 * 平面坐标转换到大地坐标（适用西安80坐标系）
		 * @param x X
		 * @param y Y
		 * @param centerLon 中央经线
		 * @param xOffset 偏移值，默认值500000m
		 * @param yOffset 偏移值，默认值0m
		 * @return 大地坐标数组，[lon,lat]
		 */
		public static function xy_LonLat_c80(x:Number, y:Number, centerLon:Number,xOffset:Number=500000,yOffset:Number=0):Array{
			return xy_LonLat(x,y,c80.a,c80.f,centerLon,xOffset,yOffset);
		}
		
		/**
		 * 平面坐标转换到大地坐标（适用北京54坐标系）
		 * @param x X
		 * @param y Y
		 * @param centerLon 中央经线
		 * @param xOffset 偏移值，默认值500000m
		 * @param yOffset 偏移值，默认值0m
		 * @return 大地坐标数组，[lon,lat]
		 */
		public static function xy_LonLat_bj54(x:Number, y:Number, centerLon:Number,xOffset:Number=500000,yOffset:Number=0):Array{
			return xy_LonLat(x,y,bj54.a,bj54.f,centerLon,xOffset,yOffset);
		}
		
		/**
		 * 平面坐标转换到大地坐标
		 * @param x X
		 * @param y Y
		 * @param a 参考椭球长半轴
		 * @param f 参考椭球扁率倒数
		 * @param centerLon 中央经线
		 * @param xOffset 偏移值，默认值500000m
		 * @param yOffset 偏移值，默认值0m
		 * @return 大地坐标数组，[lon,lat]
		 */
		public static function xy_LonLat(x:Number, y:Number, a:Number, f:Number, centerLon:Number,xOffset:Number=500000,yOffset:Number=0):Array{
			var L:Number = 0; var B:Number = 0;
			y -= yOffset;
			x -= xOffset; //为了避免横坐标出现负值，高斯- 克吕格投影与UTM 北半球投影中规定将坐标纵轴西移500 公里当作起始轴，而UTM 南半球投影除了将纵轴西移500 公里外，横轴南移10000 公里。这里只考虑高斯- 克吕格投影
			
			if (x > 1000000) {
				//				alert("坐标类型错误，应使用自然坐标");
				return null;
			}
			var ee:Number = (2 * f - 1) / f / f;       //第一偏心率的平方
			var ee2:Number = ee / (1 - ee);            //第二偏心率的平方
			var cA:Number, cB:Number, cC:Number, cD:Number, cE:Number;
			cA = 1 + 3 * ee / 4 + 45 * ee * ee / 64 + 175 * Math.pow(ee, 3) / 256 + 11025 * Math.pow(ee, 4) / 16384;
			cB = 3 * ee / 4 + 15 * ee * ee / 16 + 525 * Math.pow(ee, 3) / 512 + 2205 * Math.pow(ee, 4) / 2048;
			cC = 15 * ee * ee / 64 + 105 * Math.pow(ee, 3) / 256 + 2205 * Math.pow(ee, 4) / 4096;
			cD = 35 * Math.pow(ee, 3) / 512 + 315 * Math.pow(ee, 4) / 2048;
			cE = 315 * Math.pow(ee, 4) / 131072;
			var Bf:Number = y / (a * (1 - ee) * cA);
			do {
				B = Bf;
				Bf = (y + a * (1 - ee) * (cB * Math.sin(2 * Bf) / 2 - cC * Math.sin(4 * Bf) / 4 + cD * Math.sin(6 * Bf) / 6) - cE * Math.sin(8 * Bf) / 8) / (a * (1 - ee) * cA);
			}
			while (Math.abs(B - Bf) > 0.00000000001);
			var N:Number = a / Math.sqrt(1 - ee * Math.pow(Math.sin(Bf), 2));
			var V2:Number = 1 + ee2 * Math.pow(Math.cos(Bf), 2);
			var it2:Number = ee2 * Math.pow(Math.cos(Bf), 2);
			var tB2:Number = Math.pow(Math.tan(Bf), 2);
			B = Bf - V2 * Math.tan(Bf) / 2 * (Math.pow(x / N, 2) - (5 + 3 * tB2 + it2 - 9 * it2 * tB2) * Math.pow(x / N, 4) / 12 + (61 + 90 * tB2 + 45 * tB2 * tB2) * Math.pow(x / N, 6) / 360);
			L = (x / N - (1 + 2 * tB2 + it2) * Math.pow(x / N, 3) / 6 + (5 + 28 * tB2 + 24 * tB2 * tB2 + 6 * it2 + 8 * it2 * tB2) * Math.pow(x / N, 5) / 120) / Math.cos(Bf);
			B = B * 180 / Math.PI;
			L = L * 180 / Math.PI;
			//求解经度
			L += centerLon;
			return [L.toFixed(5), B.toFixed(5)];
		}
		
		
		/**
		 * 由纬度求解子午线弧长
		 * @param lat 纬度
		 * @param a 参考椭球长半轴
		 * @param f 参考椭球扁率倒数
		 * @return 子午线弧长
		 */		
		public static function meridianLength(lat:Number, a:Number, f:Number):Number{
			var ee:Number = (2 * f - 1) / f / f; //第一偏心率的平方 
			var rB:Number = lat * Math.PI / 180; //将度转化为弧度
			//子午线弧长公式的系数
			var cA:Number, cB:Number, cC:Number, cD:Number, cE:Number;
			cA = 1 + 3 * ee / 4 + 45 * Math.pow(ee, 2) / 64 + 175 * Math.pow(ee, 3) / 256 + 11025 * Math.pow(ee, 4) / 16384;
			cB = 3 * ee / 4 + 15 * Math.pow(ee, 2) / 16 + 525 * Math.pow(ee, 3) / 512 + 2205 * Math.pow(ee, 4) / 2048;
			cC = 15 * Math.pow(ee, 2) / 64 + 105 * Math.pow(ee, 3) / 256 + 2205 * Math.pow(ee, 4) / 4096;
			cD = 35 * Math.pow(ee, 3) / 512 + 315 * Math.pow(ee, 4) / 2048;
			cE = 315 * Math.pow(ee, 4) / 131072;
			//子午线弧长
			return a * (1 - ee) * (cA * rB - cB * Math.sin(2 * rB) / 2 + cC * Math.sin(4 * rB) / 4 - cD * Math.sin(6 * rB) / 6 + cE * Math.sin(8 * rB) / 8);
		}
	}
}