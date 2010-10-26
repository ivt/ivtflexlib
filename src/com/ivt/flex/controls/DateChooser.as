package com.ivt.flex.controls
{

	import mx.collections.ICollectionView;
	import mx.core.UIFTETextField;
	import mx.core.UITextField;
	import mx.events.DateChooserEvent;
	import mx.controls.DateChooser;
	import mx.core.mx_internal;

	import flash.display.DisplayObject;

	/**
	 * The colour to show highlighted dates. This will set the background of the text field representing the highlighted
	 * day to highlightColour.
	 */
	[ Style( name="highlightColour" ) ]

	/**
	 * This is adapted and enhanced from the code at:
	 * http://flashcrafter.org.ua/content/datechooser-cook-page-emphasizing-some-dates
	 * Cheers.
	 */
	public class DateChooser extends mx.controls.DateChooser
	{

		private var _highlightedDates:Object;
		private var _highlightedDatesChanged:Boolean;

		public function DateChooser()
		{
			super();
		}

		/**
		 * Adds an event listener to the internal dateGrid object, waiting to hear when it changes its view.
		 */
		protected override function createChildren():void
		{
			super.createChildren();
			this.mx_internal::dateGrid.addEventListener( DateChooserEvent.SCROLL, this.onScroll );
		}

		private function onScroll( event:DateChooserEvent ):void
		{
			_highlightedDatesChanged = true;
			invalidateProperties();
		}

		
		[Bindable("scroll")]
    	[Bindable("viewChanged")]

		/**
		 * Allows for values of below 0 and above 11.
		 * If either are identified, we will change the year accordingly.
		 * If, for example, you supply a value of -20, the displayedYear will change by 2. 
		 * @param value
		 */
		public override function set displayedMonth( value:int ):void
		{
			if( value < 0 )
			{
				super.displayedMonth = 12 + (value % 12);
			}
			else
			{
				super.displayedMonth = value % 12;
			}
			super.displayedYear = super.displayedYear + ( value / 12 );
		}

		/**
		 * Highlighted dates do offer anything other than a coloured in set of dates.
		 * They do not have any special functionality beyond looking different.
		 * @param value Must be a collection of date objects.
		 */
		public function set highlightedDates( value:Object ):void
		{
			if ( this._highlightedDates != value )
			{
				this._highlightedDates = value;
				this._highlightedDatesChanged = true;
				this.invalidateProperties();
			}
		}

		protected override function commitProperties():void
		{
			super.commitProperties();
			
			if ( this._highlightedDatesChanged )
			{
				this._highlightedDatesChanged = false;
				this.clearHighlight();

				for each ( var date:Date in this._highlightedDates )
				{
					if ( date.month == this.displayedMonth && date.fullYear == this.displayedYear )
					{
						this.highlightDay( date.date );
					}
				}
			}
		}

		/**
		 * Remove all highlights from previously highlighted items.
		 */
		private function clearHighlight(  ):void
		{
			for ( var i:uint = 0; i < this.mx_internal::dateGrid.numChildren; i++ )
			{
				if ( this.mx_internal::dateGrid.getChildAt(i) is UITextField )
				{
					var child:DisplayObject = this.mx_internal::dateGrid.getChildAt( i );
					if ( child is UITextField )
					{
						( child as UITextField ).background = false;
					}
				}
			}
		}

		/**
		 * Find a reference to the correct text renderer for the specified day, turn its background on and set its colour.
		 * @param day
		 */
		private function highlightDay( day:Number ):void 
		{
			var startCol:Number = this.mx_internal::dateGrid.mx_internal::getOffsetOfMonth( this.displayedYear, this.displayedMonth );
			var lastDay:Number = this.mx_internal::dateGrid.mx_internal::getNumberOfDaysInMonth( this.displayedYear, this.displayedMonth );
			if ( day < 1 ) return;
			if ( day > lastDay ) return;

			// calculate row and column of the day
			var index:int = startCol + day - 1;
			var col:int = index % 7;
			var row:int = 1 + Math.floor( index / 7 );

			var block:DisplayObject = this.mx_internal::dateGrid.mx_internal::dayBlocksArray[ col ][ row ];
			if ( block is UITextField )
			{
				( block as UITextField ).background = true;
				( block as UITextField ).backgroundColor = this.getStyle( 'highlightColour' ) ? this.getStyle( 'highlightColour' ) : 0xdddddd;
			}

		}
	}
}