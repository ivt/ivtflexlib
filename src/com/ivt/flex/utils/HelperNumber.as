
package com.ivt.flex.utils
{
	public class HelperNumber
	{
		public static const SUFFIXES:Array = [ "", "k", "M", "G", "T" ];

		public static function formatShorthand( number:Number ):String
		{
			var suffixIndex:int = 0;
			var tmp:Number = number / 1000;

			while( tmp > 1 )
			{
				suffixIndex++;
				tmp /= 1000;
			}

			return (number / Math.pow( 1000, suffixIndex )).toFixed( 0 ) + HelperNumber.SUFFIXES[ suffixIndex ];
		}
	}
}
