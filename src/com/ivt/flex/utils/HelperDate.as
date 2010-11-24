package com.ivt.flex.utils
{
	import mx.formatters.DateFormatter;
	import mx.utils.ObjectUtil;
	
	
	public class HelperDate
	{
		public static const MYSQL_DATE_FORMAT:String      = "YYYY-MM-DD";
		public static const MYSQL_TIME_FORMAT:String      = "J:NN:SS";
		public static const MYSQL_DATE_TIME_FORMAT:String = "YYYY-MM-DD J:NN:SS";

		/**
		 * PHP dates from brilliance come in UNIX timestamp from, as the number of *seconds* from
		 * epoch, whereas the Date in ActionScript is the number of *milliseconds* from epoch.
		 * Also, the times from the server are UTC times.
		 */
		public static function fromUtcUnixTimestamp( timestamp:Object ):Date
		{
			return new Date( Number( timestamp ) * 1000 );
		}
		
		/**
		 * Convert to UTC timestamp and divide by 1000 to change from *milliseconds* to *seconds* 
		 * since 1 Jan 1970.
		 */
		public static function toUtcUnixTimestamp( date:Date ):int
		{
			return new Date( date.fullYearUTC, date.monthUTC, date.dayUTC, date.hoursUTC, date.minutesUTC, date.secondsUTC, date.millisecondsUTC ).time / 1000;
		}
		
		/**
		 * Convert MySQL DATETIME into Date
		 * Expects date to be in UTC format
		 * 
		 * If you pass in a non UTC date, you'll need to set convertUTC to false
		 */
		public static function fromMySQLDateTime( date:String, convertUTC:Boolean = true ):Date
		{
			if( !date )
			{
				return null;
			}
			
			var parts:Array = date.split( ' ' );
			var dateParts:Array = String( parts[0] ).split( '-' );
			var timeParts:Array = String( parts[1] ).split( ':' );
			
			if( Number( dateParts[0] ) == 0 )
			{
				return null;
			}
			
			var newDate:Date = new Date();
			if( convertUTC )
			{
				newDate.setUTCFullYear( dateParts[0], Number( dateParts[1] ) - 1, Number( dateParts[2] ) );
				newDate.setUTCHours( timeParts[0], timeParts[1], timeParts[2] );
			}
			else
			{
				newDate.setFullYear( dateParts[0], Number( dateParts[1] ) - 1, Number( dateParts[2] ) );
				newDate.setHours( timeParts[0], timeParts[1], timeParts[2] );
			}
			
			return newDate;
		}
		
		/**
		 * Convert MySQL DATE into Date
		 * Expects date to be in UTC format
		 */
		public static function fromMySQLDate( date:String ):Date
		{
			if( date )
			{
				var parts:Array = date.split( ' ' );
				var dateParts:Array = String( parts[0] ).split( '-' );
				
				if( Number( dateParts[0] ) == 0 )
				{
					return null;
				}
				
				var newDate:Date = new Date();
				newDate.setUTCFullYear( dateParts[0], Number( dateParts[1] ) - 1, Number( dateParts[2] ) );
				
				return newDate;
			}
			
			return null;
		}

		/**
		 * Interrogates the type information of date and attempts to create a date object from it.
		 * Supports Dates,  Strings and Numbers/ints.
		 * If date is a String, we presume it is a mysql string.
		 * If it is a number, we presume it is an actionscript timestamp (time since epoch in MILLIseconds).
		 * Returns null if we cannot convert it.
		 */
		public static function fromMiscFormat( date:Object, convertUTC:Boolean = true ):Date
		{
			if ( date is Date )
			{
				return date as Date;
			}
			else if ( date is String )
			{
				var dateStr:String = date as String;
				if( dateStr.indexOf( ":" ) >= 0 )
				{
					return fromMySQLDateTime( dateStr, convertUTC );
				}
				else
				{
					return fromMySQLDate( dateStr );
				}
			}
			else if ( date is Number )
			{
				return new Date( Number( date ) );
			}
			else
			{
				return null;
			}
		}
		
		/**
		 * Returns the difference between two dates in days.
		 * If date2 is not supplied, default to the difference between date1 and now.
		 */
		public static function diff( date1:Date, date2:Date = null ):int
		{
			if ( date2 == null )
			{
				date2 = new Date();
			}
			
			/* To get accurate date differences, nuke the time
			* The problem is the difference between yesterday at 10pm and today at 6am
			* is less than 24 hours, which would return 0, or today.  But yesterday is
			* not today is it?  Nope.  So time becomes irrelevant
			*/
			var date1Compare:Date = ObjectUtil.copy( date1 ) as Date;
			var date2Compare:Date = ObjectUtil.copy( date2 ) as Date;
			
			date1Compare.setHours( 0, 0, 0, 0 );
			date2Compare.setHours( 0, 0, 0, 0 );
			
			return ( date2Compare.getTime() - date1Compare.getTime() ) / ( 1000 * 60 * 60 * 24 );
		}
		
		/**
		 * Returns the difference between two dates in hours.
		 * If date2 is not supplied, default to the difference between date1 and now.
		 */
		public static function hourDiff( date1:Date, date2:Date = null ):Number
		{
			if ( date2 == null )
			{
				date2 = new Date();
			}
			
			return ( date2.time - date1.time ) / ( 1000 * 60 * 60 );
		}

		/**
		 * Returns the difference between two dates in seconds.
		 * If date2 is not supplied, default to the difference between date1 and now.
		 * A negative value means that the date is in the future.
		 */
		public static function secondsDiff( date1:Date, date2:Date = null ):Number
		{
			if ( date2 == null )
			{
				date2 = new Date();
			}

			return ( date2.time - date1.time ) / 1000;
		}

		/**
		 * Turn a number of seconds into a string such as '3 days 13 hours 30 mins
		 * @param seconds
		 * @param units An array containing any combination of 'minutes', 'hours', 'days', 'seconds'
		 */
		public static function formatDuration( seconds:Number, units:Array = null ):String
		{
			if ( seconds == 0 )
			{
				return "";
			}
			else if ( seconds < 0 )
			{
				seconds = -seconds;
			}

			if ( units == null )
			{
				units = [ "minutes", "hours", "days" ];
			}

			var format:String = "";
			var value:int = seconds % 60;
			if ( HelperArray.getItemIndex( "seconds", units ) != -1 && value != 0 )
			{
				format = value + ( value == 1 ? " second " : " seconds " ) + format;
			}

			var minutes:int = seconds / 60;
			value = minutes % 60;
			if ( HelperArray.getItemIndex( "minutes", units ) != -1 && value != 0 )
			{
				format = value + ( value == 1 ? " minute " : " minutes " ) + format;
			}

			var hours:int = minutes / 60;
			value = hours % 24;
			if ( HelperArray.getItemIndex( "hours", units ) != -1 && value != 0 )
			{
				format = value + ( value == 1 ? " hour " : " hours " ) + format;
			}

			var days:int = hours / 24;
			value = days % 7;
			if ( HelperArray.getItemIndex( "days", units ) != -1 && value != 0 )
			{
				format = value + ( value == 1 ? " day " : " days " ) + format;
			}

			var weeks:int = days / 7;
			if ( HelperArray.getItemIndex( "weeks", units ) != -1 && weeks != 0 )
			{
				format = weeks + ( weeks == 1 ? " week " : " weeks " ) + format;
			}
			
			return format;
		}

		/**
		 * Turn a number of seconds into a string such as '3:40:15'
		 * @param seconds
		 * @param showSeconds
		 */
		public static function formatDurationTime( seconds:Number, showSeconds:Boolean = true ):String
		{
			if ( seconds == 0 )
			{
				return "";
			}
			else if ( seconds < 0 )
			{
				seconds = -seconds;
			}

			var format:String = "";
			if( showSeconds )
			{
				format = ":" + ( seconds % 60 );
			}

			var minutes:int = seconds / 60;
			format = ":" + ((minutes % 60) < 10 ? "0" : "") + ( minutes % 60 ) + format;

			var hours:int = minutes / 60;
			format = ( hours % 24 ) + format;

			return format;
		}

		public static function formatDate( date:Date, format:String = null, full:Boolean = false ):String
		{
			var dateFormater:DateFormatter = new DateFormatter();
			if( format != null )
			{
				dateFormater.formatString = format;
			}
			else
			{
				var monthFormat:String = full ? "MMMM" : "MMM";
				var yearFormat:String = full ? "YYYY" : "YY";
				var diff:Number = HelperDate.diff( date );
				if( diff < -365 )
				{
					format = "D " + monthFormat + " " + yearFormat;
				}
				else if( diff < -7 )
				{
					format = "D " + monthFormat;
				}
				else if( diff < -1 )
				{
					format = "EEEE";
				}
				else if( diff == -1 )
				{
					return "Tomorrow";
				}
				else if( diff == 0 )
				{
					return "Today";
				}
				else if( diff == 1 )
				{
					return "Yesterday";
				}
				else if( diff < 7 )
				{
					format = "last EEEE";
				}
				else if( diff < 365 && date.getFullYear() == new Date().getFullYear() )
				{
					format = "D " + monthFormat;
				}
				else
				{
					format = "D " + monthFormat + " " + yearFormat;
				}
				
				dateFormater.formatString = format;
			}
			
			return ( date ) ? HelperString.ucFirst( dateFormater.format( date ) ) : '';
		}

		public static function formatTime( date:Date, format:String = 'L:NN A' ):String
		{
			var dateFormatter:DateFormatter = new DateFormatter();
			dateFormatter.formatString = format;
			return ( date ) ? dateFormatter.format( date ) : '';
		}
		
		public static function formatDateTime( date:Date, format:String = null, full:Boolean = false ):String
		{
			var dateFormater:DateFormatter = new DateFormatter();
			if( format != null )
			{
				dateFormater.formatString = format;
			}
			else
			{
				var monthFormat:String = full ? "MMMM" : "MMM";
				var yearFormat:String = full ? "YYYY" : "YY";
				var diff:Number = HelperDate.diff( date );
				if( diff < -365 )
				{
					format = "D " + monthFormat + " " + yearFormat + " L:NN A";
				}
				else if( diff < -7 )
				{
					format = "D " + monthFormat + " L:NN A";
				}
				else if( diff < -1 )
				{
					format = "EEEE L:NN A";
				}
				else if( diff == -1 )
				{
					format = "tomorrow L:NN A";
				}
				else if( diff == 0 )
				{
					format = "L:NN A";
				}
				else if( diff == 1 )
				{
					format = "yesterday L:NN A";
				}
				else if( diff < 7 )
				{
					format = "last EEEE L:NN A";
				}
				else if( diff < 365 && date.getFullYear() == new Date().getFullYear() )
				{
					format = "D " + monthFormat + " L:NN A";
				}
				else
				{
					format = "D " + monthFormat + " " + yearFormat + " L:NN A";
				}
				
				dateFormater.formatString = format;
			}

			return ( date ) ? HelperString.ucFirst( dateFormater.format( date ) ) : '';
		}

		public static function formatDateTimeRange( date1:Date, date2:Date, full:Boolean = false ):String
		{
			var monthFormat:String = full ? "MMMM" : "MMM";
			var yearFormat:String = full ? "YYYY" : "YY";
			var format1:String;
			var format2:String;

			// Ensure the order is earliest to latest
			if( date1 > date2 )
			{
				var tmp:Date = date1;
				date1 = date2;
				date2 = tmp;
			}

			if( date1.fullYear != date2.fullYear )
			{
				format1 = "D " + monthFormat + " " + yearFormat + " L:NN A";
				format2 = "D " + monthFormat + " " + yearFormat + " L:NN A";
			}
			else if( date1.month == date2.month && date1.date == date2.date )
			{
				format2 = "L:NN A";
			}

			return HelperDate.formatDateTime( date1, format1, full ) + " to " + HelperDate.formatDateTime( date2, format2, full );
		}

		public static function formatDiff( date1:Date, date2:Date = null ):String
		{
			var diff:int = HelperDate.diff( date1, date2 );
			var formattedDiff:String = '';
			diff = ( diff < 0 ) ? -diff : diff;

			if( diff < 30 )
			{
				var s:String = ( diff.toFixed( 0 ) == '1' ) ? '' : 's';
				formattedDiff = diff.toString() + " day" + s;
			}
			else if( diff < 365 )
			{
				var monthDiff:Number = diff / 30;
				s = ( monthDiff.toFixed( 0 ) == '1' ) ? '' : 's';
				formattedDiff = monthDiff.toFixed( 0 ) + " month" + s;
			}
			else
			{
				var yearDiff:Number = diff / 365;
				s = ( yearDiff.toFixed( 0 ) == '1' ) ? '' : 's';
				formattedDiff = yearDiff.toFixed( 0 ) + " year" + s;
			}
			
			return formattedDiff;
		}
		
		/**
		 * Converts a day (Monday, Tuesday, etc. ) into a date
		 * Always returns the date for this week, so if it's wednesday and you ask for Monday
		 * it will return a date in the past.  If you ask for Saturday, it will return a date
		 * in the future.
		 * 
		 * The weekoffset allows you to move back or forward in weeks, so monday last week ( 'monday', -1 )
		 * or thursday in 2 weeks ( 'thursday', 2 )
		 */
		public static function getDateFromDay( day:String, weekOffset:int = 0 ):Date
		{
			var dayArray:Array = ['sunday','monday','tuesday','wednesday','thursday','friday','saturday'];
			var dayInt:int = dayArray.indexOf( day.toLowerCase() );
			var today:Date = new Date();
			var todayInt:int = today.getDay();
			
			if( dayInt != -1 )
			{
				return new Date( today.getFullYear(), today.getMonth(), today.getDate() - ( todayInt - dayInt ) + ( weekOffset * 7 ) );
			}
			else
			{
				throw( new Error( 'There is no such day as ' + day + '.' ) );
			}
		}

		/**
		 * Returns the time portion of a date as a value containing the number of seconds
		 * that have elapsed since midnight of that date.
		 */
		public static function getSecondsSinceMidnight( date:Date ):Number
		{
			return ( date.seconds + (date.minutes * 60) + (date.hours * 60 * 60) );
		}

		/* Flex provides no way to gather information about the user's timezone other than the offset to UTC.
		 * These functions try to infer information about the user's timezone if possible.
		 * We could also try to figure out the actual timezone using a large table of timezone data that
		 * would need to be maintained each year to take into account changes in DST, but that would be
		 * painful so we won't do that.
		 * No function to find the start and end times of DST yet. I assume that this could be achieved
		 * using a binary search.
		 */

		/**
		 * Tries to determine if the user's timezone observes daylight savings.
		 * We get two dates, one in the middle and one at the end of the year.
		 * If their timezone offsets differ then the zone observes daylight savings.
		 */
		public static function timeZoneHasDaylightSavings():Boolean
		{
			var midYear:Date = new Date();
			var endYear:Date = new Date();

			midYear.month = 5;  // June
			midYear.date = 1;
			endYear.month = 11; // December
			endYear.date = 1;

			return ( midYear.getTimezoneOffset() - endYear.getTimezoneOffset() ) != 0;
		}

		/**
		 * Tries to determine if daylight savings is active in the users timezone for the given date.
		 * We get two dates, one in the middle and one at the end of the year.
		 * If their timezone offsets differ the then zone observes daylight savings, then if the date's
		 * timezone offset is the same as the greatest, daylight savings is active ... I hope.
		 */
		public static function isInDaylightSavings( date:Date = null ):Boolean
		{
			if( null == date )
			{
				date = new Date();
			}

			var midYear:Date = new Date( date.fullYear, 5, 1 );  // June
			var endYear:Date = new Date( date.fullYear, 11, 1 ); // December

			return ( midYear.getTimezoneOffset() - endYear.getTimezoneOffset() ) != 0 &&
			       date.getTimezoneOffset() == Math.min( midYear.getTimezoneOffset(), endYear.getTimezoneOffset() );
		}
	}
}
