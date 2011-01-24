package com.ivt.flex.utils
{
import mx.collections.ArrayCollection;
import mx.utils.ArrayUtil;

	/**
	 * Performs functions on both arrays and Vectors. For all methods, the array parameter is of type Object.
	 * Do not abuse this. It is impossible to check if it is an array or vector, because Generic vectors (Vector.<Bleh>)
	 * are not Vectors (according to the 'is' deelio).
	 */
	public class HelperArray
	{

		/**
		 * Same as PHPs implode function. Takes an array/arraycollection/anything which you can 'for each' over, and
		 * concatenates each item.toString() together with the delimiter inbetween each value.
		 * @param array
		 * @param delimiter
		 * @return All items inside array concatenated together, delimited by delimiter.
		 */
		/*
		Oops, I clearly haven't seen Array.join()...
		public static function implode( array:Object, delimiter:String = "," ):String
		{
			var string:String = "";
			for each( var item:Object in array )
			{
				if ( item != null )
				{
					string += delimiter + item.toString();
				}
			}

			if ( string.length > 0 )
			{
				string = string.substr( delimiter.length );
			}
			
			return string;
		}*/

		/***
		 * Combines an arbitrary amount of array like objects (ArrayCollection/Vector/Array, literaly ANYTHING WHICH
		 * CAN BE LOOPED OVER WITH A FOR EACH LOOP).
		 * @param arrays
		 * @return Combination of all items
		 */
		public static function merge( ...arrays ):Array
		{
			var tmp:Array = new Array();
			for each ( var array:Object in arrays )
			{
				for each ( var item:Object in array )
				{
					tmp.push( item );
				}
			}
			return tmp;
		}

		/**
		 * Extracts a single property from each item in the array, and returns a new
		 * array containing these values. Useful, for example, you have an array of
		 * records, and you just want the record serials to send to the server.
		 */
		public static function extractProperty( array:Object, property:String ):Array
		{
			var tmp:Array = new Array();
			for each( var item:Object in array )
			{
				if ( item != null )
				{
					if ( item.hasOwnProperty( property ) )
					{
						tmp.push( item[ property ] );
					}
					else
					{
						trace( "Property '" + property + "' not found during HelperArray.extractProperty()" );
					}
				}
			}
			return tmp;
		}

		/**
		 * Returns true if all of the items in both source and destination are the same objects.
		 * @param source Object which supports living inside a for-each
		 * @param destination Object which supports living inside a for-each
		 * @return Boolean
		 */
		public static function equals( source:Object, destination:Object ):Boolean
		{
			if ( source.length != destination.length )
			{
				return false;
			}
			else
			{
				for each ( var x:Object in source )
				{
					var foundX:Boolean = false;
					for each ( var y:Object in destination )
					{
						if ( x == y )
						{
							foundX = true;
							break;
						}
					}
					if ( !foundX )
					{
						return false;
					}
				}
			}
			return true;
		}

		/**
		 *   Returns the index of the item in the Array/Vector/ArrayCollection/etc.
		 * If it is an array, it will just be forwarded to ArrayUtil.getItemIndex().
		 * Otherwise it will loop through the list and search for the item ourselves.
		*  @return The index of the item, and -1 if the item is not in the list.
		*/
		public static function getItemIndex( item:Object, array:Object ):int
		{
			if ( array != null )
			{
				if ( array is Array )
				{
					return ArrayUtil.getItemIndex( item, array as Array );
				}
				else if ( array.hasOwnProperty( 'length' ) )
				{
					for ( var i:int = 0; i < array.length; i ++ )
					{
						if ( array[ i ] == item )
						{
							return i;
						}
					}
				}
			}

			return -1;
		}

		/**
		 * Performs a shallow copy of a vector.
		 * @param source
		 * @param destination
		 */
		public static function copy( source:Object, destination:Object ):void
		{
			if ( source != null )
			{
				for each( var item:Object in source )
				{
					if ( destination is ArrayCollection )
					{
						destination.addItem( item );
					}
					else
					{
						destination.push( item );
					}
				}
			}
		}

		/**
		 * Search through each item looking for an item where the property 'property' matches 'value'.
		 * @param value
		 * @param property
		 * @param array
		 * @return int Returns -1 if not found, the index otherwise.
		 */
		public static function getItemIndexByProperty( value:Object, property:String, array:Object ):int
		{
			if ( array == null || !array.hasOwnProperty( "length" ) )
			{
				return -1;
			}
			else
			{
				for ( var i:int = 0; i < array.length; i ++ )
				{
					var item:Object = array[ i ];
					if ( item != null && item.hasOwnProperty( property ) && item[ property ] == value )
					{
						return i;
					}
				}
				return -1;
			}
		}

		/**
		 * Search through each item looking for an item where the property 'property' matches 'value'.
		 * @param value
		 * @param property
		 * @param array
		 * @return * Returns null if not found, the item otherwise.
		 */
		public static function getItemByProperty( value:Object, property:String, array:Object, childrenProperty:String = null ):*
		{
			if ( array == null || !array.hasOwnProperty( "length" ) )
			{
				return null;
			}
			else
			{
				for ( var i:int = 0; i < array.length; i ++ )
				{
					var item:Object = array[ i ];
					if ( item != null )
					{
						if ( item.hasOwnProperty( property ) && item[ property ] == value )
						{
							return item;
						}
						else if ( childrenProperty != null && item.hasOwnProperty( childrenProperty ) )
						{
							item = getItemByProperty( value, property, item[ childrenProperty ], childrenProperty );
							if ( item != null )
							{
								return item;
							}
						}
					}
				}
				return null;
			}
		}
	}
}