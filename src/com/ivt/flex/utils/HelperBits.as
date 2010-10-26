package com.ivt.flex.utils
{
	public class HelperBits
	{
		public static function isBitSet( bit:uint, bits:uint ):Boolean
		{
			return (bits & (1 << bit)) == (1 << bit);
		}

		public static function setBit( bit:uint, bits:uint ):uint
		{
			return bits | (1 << bit);
		}

		public static function unSetBit( bit:uint, bits:uint ):uint
		{
			return bits & ~(1 << bit);
		}
	}
}
