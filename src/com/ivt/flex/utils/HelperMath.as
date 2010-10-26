package com.ivt.flex.utils
{
	/**
	 * A collection of useful maths functions.
	 */
	public class HelperMath
	{
		/**
		 * Returns the floor of the number specified. The floor is the closest integer
		 * that is less than or equal to a multiple of the specified nearest number.
		 * @param value The value to be rounded down.
		 * @param nearest The number to round to.
		 * @return Number An integer that is both closest to, and less than or equal to, a multiple of the parameter nearest.
		 */
		public static function floor( value:Number, nearest:Number = 1 ):Number
		{
			return Math.floor( Math.floor( value / nearest ) * nearest );
		}

		/**
		 * Rounds the value up or down to the integer closest to a multiple of the specified nearest number.
		 * If the value is equidistant from the two nearest values, it is rounded up.
		 * @param value The value to be rounded.
		 * @param nearest The number to round to.
		 * @return Number An integer that is rounded to the nearest multiple of the parameter nearest.
		 */
		public static function round( value:Number, nearest:Number = 1 ):Number
		{
			return Math.round( Math.round( value / nearest ) * nearest );
		}

		/**
		 * Returns the ceiling of the number specified. The ceiling is the closest integer
		 * that is greater than or equal to a multiple of the specified nearest number.
		 * @param value The value to be rounded up.
		 * @param nearest The number to round to.
		 * @return Number An integer that is both closest to, and greater than or equal to, a multiple of the parameter nearest.
		 */
		public static function ceil( value:Number, nearest:Number = 1 ):Number
		{
			return Math.ceil( Math.ceil( value / nearest ) * nearest );
		}
	}
}