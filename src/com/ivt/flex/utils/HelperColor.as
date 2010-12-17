package com.ivt.flex.utils
{
	import mx.utils.ColorUtil;

	public class HelperColor extends ColorUtil
	{
		public static function interpolate( rgb1:uint, rgb2:uint, percent:Number ):uint
		{
			var r1:Number = (rgb1 >> 16) & 0xFF;
			var g1:Number = (rgb1 >> 8) & 0xFF;
			var b1:Number = rgb1 & 0xFF;

			var r2:Number = (rgb2 >> 16) & 0xFF;
			var g2:Number = (rgb2 >> 8) & 0xFF;
			var b2:Number = rgb2 & 0xFF;

			return ((r1 + ((r2 - r1) * percent)) << 16) |
				   ((g1 + ((g2 - g1) * percent)) << 8) |
					(b1 + ((b2 - b1) * percent));
		}
	}
}