package com.ivt.flex.controls
{
	import com.ivt.flex.utils.HelperArray;

	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.engine.FontWeight;
	import flash.ui.Keyboard;
	
	import flashx.textLayout.formats.TextLayoutFormat;

	import mx.controls.DateChooser;
	import mx.core.UIComponent;
	import mx.events.CalendarLayoutChangeEvent;
	import mx.events.DateChooserEvent;
	import mx.events.FlexEvent;
	import mx.events.FlexMouseEvent;
	import mx.events.PropertyChangeEvent;
	import mx.events.SandboxMouseEvent;
	import mx.formatters.DateFormatter;
	import mx.managers.IFocusManagerComponent;
	import mx.managers.ISystemManager;
	import mx.managers.PopUpManager;

	import spark.components.RichEditableText;

	import spark.components.TextInput;
	import spark.components.supportClasses.ButtonBase;
	import spark.components.supportClasses.SkinnableComponent;


	[Event(name="change", type="flash.events.Event")]


	public class DateTimeChooser extends SkinnableComponent implements IFocusManagerComponent
	{
		// Formatting details : http://livedocs.adobe.com/flex/3/langref/mx/formatters/DateFormatter.html
		public static const FORMAT_DATE:String		= "DD/MM/YYYY";
		public static const FORMAT_TIME:String		= "L:NN A";
		public static const FORMAT_TIME_24:String	= "J:NN";
		public static const FORMAT_DATETIME:String	= "DD/MM/YYYY L:NN A";

		private static const TYPE_UNKNOWN:int	= -1;
		private static const TYPE_AMPM:int		= 0;
		private static const TYPE_SECOND:int	= 1;
		private static const TYPE_MINUTE:int	= 2;
		private static const TYPE_HOUR:int		= 3;
		private static const TYPE_DATE:int		= 4;
		private static const TYPE_MONTH:int		= 5;
		private static const TYPE_YEAR:int		= 6;

		private static const HOUR_24:int = 0;
		private static const HOUR_23:int = 1;
		private static const HOUR_12:int = 3;
		private static const HOUR_11:int = 2;

		private static const DAYS_IN_MONTH:Array = [ 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 ];

		/**
		 * Determines if the dates/times automatically increase as the currently changed value wraps around.
		 */
		public var allowRollOver:Boolean = true;

		/**
		 * The amount to increase the value when paging up and down.
		 * Don't set this to be greater than half the smallest interval of values (or basically 6)
		 */
		private var _pageSize:int = 5;

		/**
		 * The minimum date and time this field is allowed to contain.
		 *
		 * <p>These properties define the minimum date and time that can
		 * be selected. A common use for this would be in the situation
		 * where you have start and end dates/times.</p>
		 */
		private var _minDate:Date;
		private var _minTime:Date;
		private var _minDateTime:Date;

		/**
		 * The maximum date and time this field is allowed to contain.
		 *
		 * <p>These properties define the maximum date and time that can
		 * be selected. A common use for this would be in the situation
		 * where you have start and end dates/times.</p>
		 */
		private var _maxDate:Date;
		private var _maxTime:Date;
		private var _maxDateTime:Date;

		// Minimums and maximums correspond to the format string in FORMAT_DATETIME.
		private var _minimums:Array = [ 0,  0,  0,  0,  1,  1,    0 ];
		private var _maximums:Array = [ 1, 59, 59, 11, 31, 12, 9999 ];

		private var _formatString:String = FORMAT_DATETIME;
		private var _selectedDate:Date;
		private var _dateChooser:mx.controls.DateChooser;
		private var _dateChooserKeyDown:Boolean = false;
		private var _dateChooserOldDate:Date;
		private var _targetIndex:int = 0;
		private var _targetStart:int = 0;
		private var _targetEnd:int = 0;
		private var _normalFormat:TextLayoutFormat;
		private var _highlightFormat:TextLayoutFormat;
		private var _cursorPos:int = 0;
		private var _hourType:int = HOUR_12;
		private var _largestType:int = TYPE_YEAR;
		private var _spinnerValue:int = 0;
		private var _spinnerMin:int = 0;
		private var _spinnerMax:int = 0;
		
		[SkinPart(required="true")]
		public var inputText:spark.components.TextInput;
		
		[SkinPart(required="false")]
		public var incrementButton:ButtonBase;
		
		[SkinPart(required="false")]
		public var decrementButton:ButtonBase;

		[SkinPart(required="false")]
		public var inputIcon:UIComponent;


		public function DateTimeChooser()
		{
			super();
		}

		override public function setFocus():void
		{
			if( this.stage )
			{
				this.stage.focus = this.inputText;
			}
		}

		override protected function isOurFocus(target:DisplayObject):Boolean
		{
			return target == this.inputText.textDisplay;
		}

		override protected function partAdded( partName:String, instance:Object ):void
		{
			super.partAdded( partName, instance );

			if( instance == this.inputText )
			{
				this.inputText.restrict = " \-0-9:/AMPamp";
				this.inputText.focusEnabled = false;
				this.inputText.addEventListener( FocusEvent.FOCUS_OUT, this.onTextChanged );
				this.inputText.addEventListener( KeyboardEvent.KEY_DOWN, this.onKeyDown );
				this.inputText.addEventListener( KeyboardEvent.KEY_UP, this.onKeyUp );
				this.inputText.addEventListener( FlexEvent.ENTER, this.onTextChanged );
				this.inputText.addEventListener( MouseEvent.CLICK, this.onClick );
				this.inputText.addEventListener( MouseEvent.MOUSE_WHEEL, this.onMouseWheel );
			}
			else if( instance == this.incrementButton )
			{
				this.incrementButton.focusEnabled = false;
				this.incrementButton.autoRepeat = true;
				this.incrementButton.addEventListener( FlexEvent.BUTTON_DOWN, onIncrementButtonDown );
			}
			else if( instance == this.decrementButton )
			{
				this.decrementButton.focusEnabled = false;
				this.decrementButton.autoRepeat = true;
				this.decrementButton.addEventListener( FlexEvent.BUTTON_DOWN, onDecrementButtonDown );
			}
			else if( instance == this.inputIcon )
			{
				if( this._largestType < TYPE_DATE )
				{
					this.inputIcon.visible = false;
					this.inputIcon.enabled = false;
				}
				this.inputIcon.focusEnabled = false;
				this.inputIcon.addEventListener( MouseEvent.CLICK, this.openDateChooser );
			}
		}

		override protected function partRemoved(partName:String, instance:Object):void
		{
			super.partRemoved(partName, instance);

			if( instance == this.inputText )
			{
				this.inputText.removeEventListener( FocusEvent.FOCUS_OUT, this.onTextChanged );
				this.inputText.removeEventListener( KeyboardEvent.KEY_DOWN, this.onKeyDown );
				this.inputText.removeEventListener( KeyboardEvent.KEY_UP, this.onKeyUp );
				this.inputText.removeEventListener( FlexEvent.ENTER, this.onTextChanged );
				this.inputText.removeEventListener( MouseEvent.CLICK, this.onClick );
				this.inputText.removeEventListener( MouseEvent.MOUSE_WHEEL, this.onMouseWheel );
			}
			else if( instance == this.incrementButton )
			{
				this.incrementButton.removeEventListener( FlexEvent.BUTTON_DOWN, onIncrementButtonDown );
			}
			else if( instance == this.decrementButton )
			{
				this.decrementButton.removeEventListener( FlexEvent.BUTTON_DOWN, onDecrementButtonDown );
			}
			else if( instance == this.inputIcon )
			{
				this.inputIcon.removeEventListener( MouseEvent.CLICK, this.openDateChooser );
			}
		}

		/**
		 * Overridden to make the form label play nice...
		 */
		override public function get baselinePosition():Number
		{
			return this.inputText.baselinePosition;
		}

		override protected function createChildren():void
		{
			super.createChildren();

			this._normalFormat = new TextLayoutFormat();
			this._normalFormat.fontWeight = FontWeight.NORMAL;
			this._highlightFormat = new TextLayoutFormat();
			this._highlightFormat.fontWeight = FontWeight.BOLD;

			this._dateChooser = new mx.controls.DateChooser();
			this._dateChooser.focusEnabled = false;
			this._dateChooser.owner = this;
			this._dateChooser.moduleFactory = this.moduleFactory;
			this._dateChooser.visible = false;
			this._dateChooser.addEventListener(CalendarLayoutChangeEvent.CHANGE, onDateChooserChange);
			this._dateChooser.addEventListener(DateChooserEvent.SCROLL, onDateChooserScroll);
			this._dateChooser.addEventListener(FlexMouseEvent.MOUSE_DOWN_OUTSIDE, onDateChooserMouseDown);
			this._dateChooser.addEventListener(FlexMouseEvent.MOUSE_WHEEL_OUTSIDE, onDateChooserMouseDown);
			this._dateChooser.addEventListener(SandboxMouseEvent.MOUSE_DOWN_SOMEWHERE, onDateChooserMouseDown);
			this._dateChooser.addEventListener(SandboxMouseEvent.MOUSE_WHEEL_SOMEWHERE, onDateChooserMouseDown);
		}

		// Getters and Setters

		[Bindable]
		public function get selectedDate():Date
		{
			return this._selectedDate;
		}

		public function set selectedDate( value:Date ):void
		{
			if( value != this._selectedDate )
			{
				var restricted:Boolean = false;
				var dateFormatter:DateFormatter = new DateFormatter();
				dateFormatter.formatString = this._formatString;

				if( null != value )
				{
					if( this._minDateTime )
					{
						if( value < this._minDateTime )
						{
							value = this._minDateTime;
							restricted = true;
						}
					}

					if( this._maxDateTime )
					{
						if( value > this._maxDateTime )
						{
							value = this._maxDateTime;
							restricted = true;
						}
					}

					var valueDate:Date = new Date( value.fullYear, value.month, value.date );
					if( this._minDate )
					{
						if ( valueDate < this._minDate )
						{
							value.fullYear = this._minDate.fullYear;
							value.month = this._minDate.month;
							value.date = this._minDate.date;
							restricted = true;
						}
					}

					if( this._maxDate )
					{
						if ( valueDate > this._maxDate )
						{
							value.fullYear = this._maxDate.fullYear;
							value.month = this._maxDate.month;
							value.date = this._maxDate.date;
							restricted = true;
						}
					}

					var valueTime:Date = new Date( 0, 0, 0, value.hours, value.minutes, value.seconds );
					if( this._minTime )
					{
						if ( valueTime < this._minTime )
						{
							value.hours = this._minTime.hours;
							value.minutes = this._minTime.minutes;
							value.seconds = this._minTime.seconds;
							restricted = true;
						}
					}

					if( this._maxTime )
					{
						if ( valueTime > this._maxTime )
						{
							value.hours = this._maxTime.hours;
							value.minutes = this._maxTime.minutes;
							value.seconds = this._maxTime.seconds;
							restricted = true;
						}
					}
				}

				this._selectedDate = value;
				if( null != this._selectedDate )
				{
					if( this._selectedDate.month == 1 && this.isLeapYear( this._selectedDate.fullYear ) )
					{
						this._maximums[ TYPE_DATE ] = DAYS_IN_MONTH[ this._selectedDate.month ] + 1;
					}
					else
					{
						this._maximums[ TYPE_DATE ] = DAYS_IN_MONTH[ this._selectedDate.month ];
					}

					this.inputText.text = dateFormatter.format( this._selectedDate );
					this.inputText.selectRange( this._cursorPos, this._cursorPos );
					this.updateSpinnerTarget();

					if( null != this._dateChooser && this._dateChooser.visible )
					{
						this._dateChooser.selectedDate = this._selectedDate;
					}

					if( restricted )
					{
						this.dispatchEvent( new Event( Event.CHANGE ) );
					}
				}
				else
				{
					this.inputText.text = "";
					this.updateSpinnerTarget();
				}
			}
		}

		[Bindable]
		public function get selectedTime():Date
		{
			var date:Date = new Date();
			date.hours = this._selectedDate.hours;
			date.minutes = this._selectedDate.minutes;
			date.seconds = this._selectedDate.seconds;
			return date;
		}

		public function set selectedTime( value:Date ):void
		{
			if ( value != null )
			{
				value.setFullYear( this.selectedDate.fullYear, this.selectedDate.month,	this.selectedDate.date );
			}
			this.selectedDate = value;
		}

		[Bindable]
		public function get formatString():String
		{
			return this._formatString;
		}

		public function set formatString( format:String ):void
		{
			if( null != format )
			{
				this._formatString = format;

				// Find the largest type in the format
				if( this._formatString.indexOf( "YY" ) != -1 )
				{
					this._largestType = TYPE_YEAR;
				}
				else if( this._formatString.indexOf( "M" ) != -1 )
				{
					this._largestType = TYPE_MONTH;
				}
				else if( this._formatString.indexOf( "D" ) != -1 )
				{
					this._largestType = TYPE_DATE;
				}
				else if( this._formatString.indexOf( "J" ) != -1 || this._formatString.indexOf( "H" ) != -1 || this._formatString.indexOf( "K" ) != -1 || this._formatString.indexOf( "L" ) != -1 )
				{
					this._largestType = TYPE_HOUR;
				}
				else if( this._formatString.indexOf( "N" ) != -1 )
				{
					this._largestType = TYPE_MINUTE;
				}
				else if( this._formatString.indexOf( "S" ) != -1 )
				{
					this._largestType = TYPE_SECOND;
				}
				else if( this._formatString.indexOf( "A" ) != -1 )
				{
					this._largestType = TYPE_AMPM;
				}

				// Adjust minimums and maximums based on the hour format
				if( this._formatString.indexOf( "J" ) != -1 )
				{
					this._minimums[ TYPE_HOUR ] = 0;
					this._maximums[ TYPE_HOUR ] = 23;
					this._hourType = HOUR_23;
				}
				else if( this._formatString.indexOf( "H" ) != -1 )
				{
					this._minimums[ TYPE_HOUR ] = 1;
					this._maximums[ TYPE_HOUR ] = 24;
					this._hourType = HOUR_24;
				}
				else if( this._formatString.indexOf( "K" ) != -1 )
				{
					this._minimums[ TYPE_HOUR ] = 0;
					this._maximums[ TYPE_HOUR ] = 11;
					this._hourType = HOUR_11;
				}
				else if( this._formatString.indexOf( "L" ) != -1 ) // Should normally be 1-12 but for the sake of rollover we want 0-11 and will handle this case specially.
				{
					this._minimums[ TYPE_HOUR ] = 0;
					this._maximums[ TYPE_HOUR ] = 11;
					this._hourType = HOUR_12;
				}

				if( this.inputText && isNaN( this.percentWidth ) && isNaN( this.explicitWidth ) )
				{
					this.inputText.widthInChars = format.length;
				}

				if( this.inputIcon )
				{
					if( this._largestType < TYPE_DATE )
					{
						this.inputIcon.visible = false;
						this.inputIcon.enabled = false;
					}
					else
					{
						this.inputIcon.visible = true;
						this.inputIcon.enabled = true;
					}
				}

				this.selectedDate = this.dateArrayToDate( this.parseDateTimeString( this.inputText.text ) ); // Force the current date to be verified and updated.
			}
		}

		[Bindable]
		public function get minDate():Date
		{
			return this._minDate;
		}

		public function set minDate( date:Date ):void
		{
			this._minDate = ( null != date ) ? new Date( date.fullYear, date.month,  date.date ) : null;
			this.selectedDate = this.dateArrayToDate( this.parseDateTimeString( this.inputText.text ) ); // Force the current date to be verified and updated.
		}

		[Bindable]
		public function get minTime():Date
		{
			return this._minTime;
		}

		public function set minTime( time:Date ):void
		{
			this._minTime = ( null != time ) ? new Date( 0, 0, 0, time.hours, time.minutes, time.seconds ) : null;
			this.selectedDate = this.dateArrayToDate( this.parseDateTimeString( this.inputText.text ) ); // Force the current date to be verified and updated.
		}

		[Bindable]
		public function get minDateTime():Date
		{
			return this._minDateTime;
		}

		public function set minDateTime( date:Date ):void
		{
			this._minDateTime = date;
			this.selectedDate = this.dateArrayToDate( this.parseDateTimeString( this.inputText.text ) ); // Force the current date to be verified and updated.
		}

		[Bindable]
		public function get maxDate():Date
		{
			return this._maxDate;
		}

		public function set maxDate( date:Date ):void
		{
			this._maxDate = ( null != date ) ? new Date( date.fullYear, date.month,  date.date ) : null;
			this.selectedDate = this.dateArrayToDate( this.parseDateTimeString( this.inputText.text ) ); // Force the current date to be verified and updated.
		}

		[Bindable]
		public function get maxTime():Date
		{
			return this._maxTime;
		}

		public function set maxTime( time:Date ):void
		{
			this._maxTime = ( null != time ) ? new Date( 0, 0, 0, time.hours, time.minutes, time.seconds ) : null;
			this.selectedDate = this.dateArrayToDate( this.parseDateTimeString( this.inputText.text ) ); // Force the current date to be verified and updated.
		}

		[Bindable]
		public function get maxDateTime():Date
		{
			return this._maxDateTime;
		}

		public function set maxDateTime( date:Date ):void
		{
			this._maxDateTime = date;
			this.selectedDate = this.dateArrayToDate( this.parseDateTimeString( this.inputText.text ) ); // Force the current date to be verified and updated.
		}

		[Bindable]
		public function get pageSize():int
		{
			return this._pageSize;
		}

		public function set pageSize( size:int ):void
		{
			if( size > 6 )
			{
				size = 6;
			}
			this._pageSize = size;
		}

		// Date Chooser

		private function openDateChooser( event:MouseEvent = null ):void
		{
			PopUpManager.addPopUp( this._dateChooser, this, false );
			this._dateChooserOldDate = this._selectedDate;
			this._dateChooser.selectedDate = this._selectedDate ? this._selectedDate : new Date();
			this._dateChooser.visible = true;
			this._dateChooser.scaleX = this.scaleX;
			this._dateChooser.scaleY = this.scaleY;
			if( this._minDate || this._maxDate )
			{
				this._dateChooser.selectableRange = { rangeStart:this._minDate, rangeEnd:this._maxDate };
			}
			else if( this._minDateTime || this._maxDateTime )
			{
				this._dateChooser.selectableRange = { rangeStart:this._minDateTime, rangeEnd:this._maxDateTime };
			}

			// Position date chooser to the right and down
			var point:Point = new Point( 0, 0 );
			if( this.inputIcon )
			{
				point.x = this.inputIcon.x;
			}
			point = this.localToGlobal( point );

			// Adjust to ensure it's always on screen
			var sm:ISystemManager = this.systemManager.topLevelSystemManager;
			var screen:Rectangle = sm.getVisibleApplicationRect();
			if( screen.right > this._dateChooser.getExplicitOrMeasuredWidth() + point.x )
			{
				// DateChooser fits to the right
				if( screen.bottom < this._dateChooser.getExplicitOrMeasuredHeight() + point.y )
				{
					// But not down
					point.y -= this._dateChooser.getExplicitOrMeasuredHeight();
				}
			}
			else
			{
				// DateChooser doesn't fit to the right
				point.x -= this._dateChooser.getExplicitOrMeasuredWidth() - this.inputIcon.width;
				if( screen.bottom < this._dateChooser.getExplicitOrMeasuredHeight() + point.y )
				{
					// Doesn't fit down either
					point.y -= this._dateChooser.getExplicitOrMeasuredHeight();
				}
				else
				{
					point.y += this.unscaledHeight;
				}
			}

			this._dateChooser.move( point.x, point.y );

			// Make sure that the text field has focus
			this.inputText.setFocus();
		}

		private function closeDateChooser():void
		{
			this._dateChooser.visible = false;
		}

		private function onDateChooserChange( event:CalendarLayoutChangeEvent ):void
		{
			var dateFormatter:DateFormatter = new DateFormatter();
			dateFormatter.formatString = this._formatString;

			var oldSelectedDate:Date = this._selectedDate;

			if( null != this._selectedDate )
			{
				this._selectedDate.setFullYear( this._dateChooser.selectedDate.getFullYear(), this._dateChooser.selectedDate.getMonth(), this._dateChooser.selectedDate.getDate() );
			}
			else
			{
				this._selectedDate = this._dateChooser.selectedDate;
			}

			if( this._selectedDate.month == 1 && this.isLeapYear( this._selectedDate.fullYear ) )
			{
				this._maximums[ TYPE_DATE ] = DAYS_IN_MONTH[ this._selectedDate.month ] + 1;
			}
			else
			{
				this._maximums[ TYPE_DATE ] = DAYS_IN_MONTH[ this._selectedDate.month ];
			}

			this.inputText.text = dateFormatter.format( this._selectedDate );
			this.inputText.selectRange( this._cursorPos, this._cursorPos );
			this.updateSpinnerTarget();

			// Only close the DateChooser if the change was caused by the mouse
			if( !this._dateChooserKeyDown )
			{
				this.closeDateChooser();
			}

			this.dispatchEvent( new Event( Event.CHANGE ) );

			if ( null == oldSelectedDate || oldSelectedDate.time != this._selectedDate.time )
			{
				this.dispatchEvent( PropertyChangeEvent.createUpdateEvent( this, 'selectedDate', oldSelectedDate, this._selectedDate ) );
			}
		}

		private function onDateChooserMouseDown( event:Event ):void
		{
			if( event is MouseEvent )
			{
				var mouseEvent:MouseEvent = MouseEvent( event );
				if( !this.hitTestPoint( mouseEvent.stageX, mouseEvent.stageY, true ) )
				{
					this.closeDateChooser();
				}
			}
			else if( event is SandboxMouseEvent )
			{
				this.closeDateChooser();
			}
		}

		private function onDateChooserScroll( event:DateChooserEvent ):void
		{
			this.dispatchEvent( event );
		}

		// Text input handling

		private function onKeyDown( event:KeyboardEvent ):void
		{
			if( this._dateChooser && this._dateChooser.visible )
			{
				if( event.keyCode == Keyboard.ESCAPE )
				{
					this.selectedDate = this._dateChooserOldDate;
					this.closeDateChooser();
				}
				else if( event.keyCode == Keyboard.ENTER )
				{
					this.closeDateChooser();
				}
				else if( event.keyCode == Keyboard.UP ||
						 event.keyCode == Keyboard.DOWN ||
						 event.keyCode == Keyboard.LEFT ||
						 event.keyCode == Keyboard.RIGHT ||
						 event.keyCode == Keyboard.PAGE_UP ||
						 event.keyCode == Keyboard.PAGE_DOWN ||
						 event.keyCode == Keyboard.HOME ||
						 event.keyCode == Keyboard.END ||
						 event.keyCode == 187 ||    // + or =
						 event.keyCode == 189 )     // - or _
				{
					this.inputText.selectRange( this._cursorPos, this._cursorPos );
					if( event.ctrlKey && event.keyCode == Keyboard.UP )
					{
						this.selectedDate = this._dateChooserOldDate;
						this.closeDateChooser();
					}
					else
					{
						this._dateChooserKeyDown = true;
						this._dateChooser.dispatchEvent( event );
						this._dateChooserKeyDown = false;
					}
				}
				event.stopPropagation();
			}
			else
			{
				if( event.keyCode == Keyboard.UP )
				{
					this.inputText.selectRange( this._cursorPos, this._cursorPos );
					if( this._spinnerValue + 1 > this._spinnerMax )
					{
						this._spinnerValue = this._spinnerMin;
					}
					else
					{
						this._spinnerValue += 1;
					}
					this.onSpinnerChanged();
				}
				else if( event.keyCode == Keyboard.DOWN )
				{
					this.inputText.selectRange( this._cursorPos, this._cursorPos );
					if( event.ctrlKey )
					{
						this.openDateChooser();
					}
					else
					{
						if( this._spinnerValue - 1 < this._spinnerMin )
						{
							this._spinnerValue = this._spinnerMax;
						}
						else
						{
							this._spinnerValue -= 1;
						}
						this.onSpinnerChanged();
					}
				}
				else if( event.keyCode == Keyboard.PAGE_UP )
				{
					this.inputText.selectRange( this._cursorPos, this._cursorPos );
					if( this._spinnerValue + this.pageSize > this._spinnerMax )
					{
						this._spinnerValue = this._spinnerMin + ((this._spinnerValue + this.pageSize) - this._spinnerMax - 1);
					}
					else
					{
						this._spinnerValue += this.pageSize;
					}
					this.onSpinnerChanged();
				}
				else if( event.keyCode == Keyboard.PAGE_DOWN )
				{
					this.inputText.selectRange( this._cursorPos, this._cursorPos );
					if( this._spinnerValue - this.pageSize < this._spinnerMin )
					{
						this._spinnerValue = this._spinnerMax + (this._spinnerValue - this.pageSize);
					}
					else
					{
						this._spinnerValue -= this.pageSize;
					}
					this.onSpinnerChanged();
				}
				else if( event.keyCode == Keyboard.ESCAPE )
				{
					this.allowRollOver = !this.allowRollOver;
				}
			}
		}

		private function onKeyUp( event:KeyboardEvent ):void
		{
			if( event.keyCode != Keyboard.UP &&
				event.keyCode != Keyboard.DOWN &&
				event.keyCode != Keyboard.PAGE_UP &&
				event.keyCode != Keyboard.PAGE_DOWN )
			{
				this._cursorPos = this.inputText.selectionAnchorPosition;
				this.updateSpinnerTarget();
			}
		}

		private function onClick( event:MouseEvent ):void
		{
			this._cursorPos = this.inputText.selectionAnchorPosition;
			this.updateSpinnerTarget();
		}

		private function onMouseWheel( event:MouseEvent ):void
		{
			if( event.delta > 0 )
			{
				if( this._spinnerValue + 1 > this._spinnerMax )
				{
					this._spinnerValue = this._spinnerMin;
				}
				else
				{
					this._spinnerValue += 1;
				}
				this.onSpinnerChanged();
			}
			else if( event.delta < 0 )
			{
				if( this._spinnerValue - 1 < this._spinnerMin )
				{
					this._spinnerValue = this._spinnerMax;
				}
				else
				{
					this._spinnerValue -= 1;
				}
				this.onSpinnerChanged();
			}
		}

		private function onTextChanged( event:Event = null ):void
		{
			this.selectedDate = this.dateArrayToDate( this.parseDateTimeString( this.inputText.text ) );
			this.dispatchEvent( new Event( Event.CHANGE ) );
		}

		// Spinner handling

		private function onIncrementButtonDown( event:FlexEvent ):void
		{
			this._spinnerValue++;
			if( this._spinnerValue > this._spinnerMax )
			{
				this._spinnerValue = this._spinnerMin;
			}
			this.onSpinnerChanged();
		}

		private function onDecrementButtonDown( event:FlexEvent ):void
		{
			this._spinnerValue--;
			if( this._spinnerValue < this._spinnerMin )
			{
				this._spinnerValue = this._spinnerMax;
			}
			this.onSpinnerChanged();
		}

		private function updateSpinnerTarget():void
		{
			var values:Array = this.parseDateTimeString( this.inputText.text );

			this._targetIndex = -1;

			for( var ii:int = 0; ii < values.length; ii++ )
			{
				if( this.inputText.selectionAnchorPosition >= values[ ii ].start && this.inputText.selectionAnchorPosition <= values[ ii ].end )
				{
					this._targetIndex = ii;
					break;
				}
			}

			if( this._targetIndex >= 0 && this._targetIndex < values.length && values[ this._targetIndex ].type != TYPE_UNKNOWN )
			{
				this._spinnerMin = this._minimums[ values[ this._targetIndex ].type ];
				this._spinnerMax = this._maximums[ values[ this._targetIndex ].type ];
				if( values[ this._targetIndex ].type == TYPE_AMPM )
				{
					this._spinnerValue = ( values[ this._targetIndex ].value == "AM" || values[ this._targetIndex ].value == "am" || values[ this._targetIndex ].value == "aM" || values[ this._targetIndex ].value == "Am" ) ? 0 : 1;
				}
				else
				{
					this._spinnerValue = parseInt( values[ this._targetIndex ].value );
				}


				if ( this.inputText.textDisplay is RichEditableText )
				{
					( this.inputText.textDisplay as RichEditableText ).setFormatOfRange( this._normalFormat, 0, this.inputText.text.length );
					this._targetStart = values[ this._targetIndex ].start;
					this._targetEnd = values[ this._targetIndex ].end;
					if( (this.focusManager.getFocus() == this) )
					{
						( this.inputText.textDisplay as RichEditableText ).setFormatOfRange( this._highlightFormat, this._targetStart, this._targetEnd );
					}
				}
			}
		}

		private function onSpinnerChanged():void
		{
			if( this.inputText.text.length == 0 )
			{
				// No date/time specified but the user wants to change it...
				this.selectedDate = new Date();
				this.dispatchEvent( new Event( Event.CHANGE ) );
				return;
			}

			var values:Array = this.parseDateTimeString( this.inputText.text );

			if( this._targetIndex >= 0 &&
				this._targetIndex < values.length &&
				values[ this._targetIndex ].type != TYPE_UNKNOWN )
			{
				if( values[ this._targetIndex ].type == TYPE_AMPM )
				{
					if( values[ this._targetIndex ].value == "AM" )
					{
						values[ this._targetIndex ].value = "PM";
					}
					else
					{
						values[ this._targetIndex ].value = "AM";
					}
				}
				else
				{
					// Handle rolling over the fields
					if( this.allowRollOver )
					{
						var currentIndex:int = this._targetIndex;
						var oldVal:int = parseInt( values[ currentIndex ].value );
						var newVal:int = this._spinnerValue;

						if( values[ this._targetIndex ].type != this._largestType )
						{
							var nextIndex:int = HelperArray.getItemIndexByProperty( values[ currentIndex ].type + 1, "type", values );
							var oldNextVal:int;

							// Loop around and check field until one hasn't been changed
							while( nextIndex > -1 && newVal != oldVal )
							{
								oldNextVal = parseInt( values[ nextIndex ].value );
								values = this.handleRollOver( oldVal, newVal, currentIndex, nextIndex, values );
								oldVal = oldNextVal;
								newVal = parseInt( values[ nextIndex ].value );
								currentIndex = nextIndex;
								nextIndex = HelperArray.getItemIndexByProperty( values[ currentIndex ].type + 1, "type", values );
							}

							this._spinnerValue = parseInt( values[ this._targetIndex ].value );
						}
						else if( this._largestType == TYPE_HOUR &&
								 this._maximums[ TYPE_HOUR ] <= 12 &&
								 ( ( oldVal < newVal - this.pageSize ) || ( oldVal > newVal + this.pageSize ) ) )
						{
							var ampmIdx:int = HelperArray.getItemIndexByProperty( TYPE_AMPM, "type", values );
							if( ampmIdx > -1 )
							{
								if( values[ ampmIdx ].value == "AM" )
								{
									values[ ampmIdx ].value = "PM";
								}
								else
								{
									values[ ampmIdx ].value = "AM";
								}
							}
						}
					}

					values[ this._targetIndex ].value = this._spinnerValue.toString();

					// Make sure the date is sensible for the month
					if( values[ this._targetIndex ].type == TYPE_MONTH )
					{
						var dateIdx:int = HelperArray.getItemIndexByProperty( TYPE_DATE, "type", values );
						if( dateIdx > -1 )
						{
							var dateVal:Number = parseInt( values[ dateIdx ].value );
							if( !isNaN( dateVal ) && dateVal > DAYS_IN_MONTH[ this._spinnerValue - 1 ] )
							{
								values[ dateIdx ].value = DAYS_IN_MONTH[ this._spinnerValue - 1 ].toString();

								// Handle leap years
								if( this._spinnerValue == 2 )
								{
									var yearIdx:int = HelperArray.getItemIndexByProperty( TYPE_YEAR, "type", values );
									if( yearIdx > -1 )
									{
										if( this.isLeapYear( parseInt( values[ yearIdx ].value ) ) )
										{
											values[ dateIdx ].value++;
										}
									}
								}
							}
						}
					}
				}

				this.selectedDate = this.dateArrayToDate( values );
				this.dispatchEvent( new Event( Event.CHANGE ) );
			}
		}

		// Date utility functions

		private function dateArrayToDate( values:Array ):Date
		{
			var date:Date;
			var day:int = 0;
			var month:int = 0;
			var year:int = 0;
			var hours:int = 0;
			var minutes:int = 0;
			var seconds:int = 0;
			var ampm:int = -1;

			if( values.length > 0 )
			{
				for each ( var val:Object in values )
				{
					switch( val.type )
					{
						case TYPE_DATE:
							day = parseInt( val.value );
							break;
						case TYPE_MONTH:
							month = parseInt( val.value ) - 1;
							break;
						case TYPE_YEAR:
							year = parseInt( val.value );
							break;
						case TYPE_MINUTE:
							minutes = parseInt( val.value );
							break;
						case TYPE_SECOND:
							seconds = parseInt( val.value );
							break;
						case TYPE_AMPM:
							ampm = val.value == "AM" ? 1 : 0;
							break;
					}
				}

				// Handle hours last as we needed to make sure that ampm was set correctly
				for each ( val in values )
				{
					switch( val.type )
					{
						case TYPE_HOUR:
							hours = parseInt( val.value );
							if( ampm != -1 && hours < 12 )
							{
								hours = ampm ? hours : hours + 12;
							}
							break;
					}
				}

				date = new Date( year, month, day, hours, minutes, seconds );
			}

			return date;
		}

		private function parseDateTimeString( value:String ):Array
		{
			var vals:Array = [];
			var delims:String = ":/- ";
			var leftDelim:String = " ";
			var pos:int = 0;
			var type:int = TYPE_UNKNOWN;
			var val:String;

			for( var ii:int = 0; ii < value.length; ii++ )
			{
				if( delims.search( value.charAt( ii ) ) != -1 )
				{
					val = value.substring( pos, ii );
					if( val != "" )
					{
						if( leftDelim == " " && (value.charAt( ii ) == "/" || value.charAt( ii ) == "-") )
						{
							var intVal:int = parseInt( val );
							if( intVal > 31 )
							{
								type = TYPE_YEAR;
							}
							else
							{
								type = TYPE_DATE;
							}
						}
						else if( leftDelim == "/" || leftDelim == "-" )
						{
							if( value.charAt( ii ) == " " )
							{
								intVal = parseInt( val );
								if( intVal > 31 )
								{
									type = TYPE_YEAR;
								}
								else
								{
									type = TYPE_DATE;
								}
							}
							else
							{
								type = TYPE_MONTH;
							}
						}
						else if( leftDelim == " " && value.charAt( ii ) == ":" )
						{
							type = TYPE_HOUR;
							if( this._hourType == HOUR_12 && parseInt( val ) == 12 )
							{
								val = "0";
							}
						}
						else if( leftDelim == ":" )
						{
							if( type == TYPE_HOUR )
							{
								type = TYPE_MINUTE;
							}
							else
							{
								type = TYPE_SECOND;
							}
						}
						else if( val == "aM" || val == "Am" || val == "AM" || val == "am" || val == "A" || val == "a" ||
								 val == "pM" || val == "Pm" || val == "PM" || val == "pm" || val == "P" || val == "p" )
						{
							type = TYPE_AMPM;
							val = val.toUpperCase();
							if( val == "A" )
							{
								val = "AM";
							}
							else if( val == "P" )
							{
								val = "PM";
							}
						}
						else
						{
							type = TYPE_UNKNOWN;
						}
					}
					else
					{
						type = TYPE_UNKNOWN;
					}

					if( type != TYPE_UNKNOWN )
					{
						vals.push( { value:val, type:type, start:pos, end:ii } );
					}
					pos = ii + 1;
					leftDelim = value.charAt( ii );
				}
			}

			// Last piece of the puzzle
			val = value.substring( pos, value.length );
			if( val != "" )
			{
				if( leftDelim == "/" || leftDelim == "-" )
				{
					intVal = parseInt( val );
					if( intVal > 31 )
					{
						type = TYPE_YEAR;
					}
					else
					{
						type = TYPE_DATE;
					}
				}
				else if( leftDelim == ":" )
				{
					if( type == TYPE_HOUR )
					{
						type = TYPE_MINUTE;
					}
					else
					{
						type = TYPE_SECOND;
					}
				}
				else if( val == "aM" || val == "Am" || val == "AM" || val == "am" || val == "A" || val == "a" ||
						 val == "pM" || val == "Pm" || val == "PM" || val == "pm" || val == "P" || val == "p" )
				{
					type = TYPE_AMPM;
					val = val.toUpperCase();
					if( val == "A" )
					{
						val = "AM";
					}
					else if( val == "P" )
					{
						val = "PM";
					}
				}
				else
				{
					type = TYPE_UNKNOWN;
				}
			}
			else
			{
				type = TYPE_UNKNOWN;
			}

			if( type != TYPE_UNKNOWN )
			{
				vals.push( { value:val, type:type, start:pos, end:value.length } );
			}

			return vals;
		}

		private function handleRollOver( oldVal:int, newVal:int, index:int, nextIndex:int, values:Array ):Array
		{
			var nextVal:int = parseInt( values[ nextIndex ].value );
			var nextValCurrent:int = nextVal;

			if( oldVal < newVal - this.pageSize )
			{
				nextVal--;
				if( nextVal < this._minimums[ values[ nextIndex ].type ] )
				{
					nextVal = this._maximums[ values[ nextIndex ].type ];
				}

				// Special cases
				if( values[ index ].type == TYPE_DATE )
				{
					// Adjust for the difference in days between the two months
					newVal += ( DAYS_IN_MONTH[ nextVal - 1 ] - DAYS_IN_MONTH[ nextValCurrent - 1 ] );

					// Handle leap years
					if( nextVal == 2 )
					{
						var yearIdx:int = HelperArray.getItemIndexByProperty( TYPE_YEAR, "type", values );
						if( yearIdx > -1 )
						{
							if( this.isLeapYear( parseInt( values[ yearIdx ].value ) ) )
							{
								newVal++;
							}
						}
					}
				}
				else if( values[ index ].type == TYPE_HOUR && this._maximums[ TYPE_HOUR ] <= 12 )
				{
					var ampmIdx:int = HelperArray.getItemIndexByProperty( TYPE_AMPM, "type", values );
					if( ampmIdx > -1 )
					{
						if( values[ ampmIdx ].value == "AM" )
						{
							values[ ampmIdx ].value = "PM";
						}
						else
						{
							values[ ampmIdx ].value = "AM";
							nextVal = nextValCurrent;
						}
					}
				}

			}
			else if( oldVal > newVal + this.pageSize )
			{
				nextVal++;
				if( nextVal > this._maximums[ values[ nextIndex ].type ] )
				{
					nextVal = this._minimums[ values[ nextIndex ].type ];
				}

				// Special case for hours
				if( values[ index ].type == TYPE_HOUR && this._maximums[ TYPE_HOUR ] <= 12 )
				{
					ampmIdx = HelperArray.getItemIndexByProperty( TYPE_AMPM, "type", values );
					if( ampmIdx > -1 )
					{
						if( values[ ampmIdx ].value == "AM" )
						{
							values[ ampmIdx ].value = "PM";
							nextVal = nextValCurrent;
						}
						else
						{
							values[ ampmIdx ].value = "AM";
						}
					}
				}
			}

			values[ index ].value = newVal.toString();
			values[ nextIndex ].value = nextVal.toString();

			return values;
		}

		private function isLeapYear( year:Number ):Boolean
		{
			return (!isNaN( year )) && (year % 4 == 0) && (year % 100 != 0) || (year % 400 == 0);
		}
	}
}