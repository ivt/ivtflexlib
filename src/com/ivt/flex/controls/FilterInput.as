package com.ivt.flex.controls
{
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import mx.collections.ICollectionView;


	[Event(name="change", type="flash.events.Event")]

	/**
	 * Enhances the spark TextInput by hooking it up to a data provider and automatically filtering it when the text
	 * changes. You can either specify one data provider or a series of data providers (if you want the filter to work
	 * on more than one list).
	 * Also incorporates the delayed change event from the DelayedTextInput which only dispatches a change event after
	 * a period without interaction (as specified by the 'delay' property).
	 */	
	public class FilterInput extends TextInput
	{
		
		[SkinState("focused")]
		
		private var _dataProvider:ICollectionView;
		private var _dataProviders:Array;
		private var _filterProperties:Array;
		private var _excludeFromFilter:Object; // Either a vector or an array, or anything else you can perform a for each over...
		
		/**
		 * The timer which keeps track of how long since the last key press.
		 * When it reaches a certain amount of time, *then* a change event is dispatched. 
		 */
		private var _timer:Timer = new Timer( 400, 1 );
		
		public function FilterInput()
		{
			super();
			
			this._timer.addEventListener( TimerEvent.TIMER_COMPLETE, this.onTimerDone );
			this.addEventListener( Event.CHANGE, this.onFilterChanged );
		}
		
		/**
		 * Called by the filter input box.
		 * Restarts the timer.
		 */
		private function onFilterChanged( event:Event ):void
		{
			this._timer.reset();
			this._timer.start();
		}
		
		/**
		 * Amount of milliseconds between the last keypress and a filter change event being
		 * dispatched. Defaults to 400.
		 */
		override public function get delay():int { return this._timer.delay; }
		override public function set delay( value:int ):void { this._timer.delay = value; }
		
		/**
		 * Listener for when the timer is finished. Dispatches a change event.
		 */
		private function onTimerDone( event:TimerEvent ):void
		{
			this.dispatchEvent( new Event( Event.CHANGE ) );
			if( this._dataProvider != null )
			{
				this._dataProvider.filterFunction = this.filterData;
				this._dataProvider.refresh();
			}
			else if ( this._dataProviders != null && this._dataProviders.length > 0 )
			{
				for each( var dataProvider:ICollectionView in this._dataProviders )
				{
					dataProvider.filterFunction = this.filterData;
					dataProvider.refresh();
				}
			}
		}
		
		public function get dataProvider():ICollectionView { return this._dataProvider; }
		public function set dataProvider( value:ICollectionView ):void { this._dataProvider = value; }
		
		public function get dataProviders():Array { return this._dataProviders; }
		public function set dataProviders( value:Array ):void { this._dataProviders = value; }
		
		public function get filterProperties():Array { return this._filterProperties; }
		public function set filterProperties( value:Array ):void { this._filterProperties = value; }
		
		public function get excludeFromFilter():Object { return this._excludeFromFilter; }
		public function set excludeFromFilter( value:Object ):void 
		{
			this._excludeFromFilter = value;
		}
		
		public function clear():void
		{
			this.text = "";
		}
		
		/**
		 * Look through the properties of 'item' and see if the values contain the filterText entered by the user.
		 * If 'filterProperties' are defined, only those properties are searched, otherwise all properties are looked at.
		 * @param item
		 * @return Boolean
		 */
		private function filterData( item:Object ):Boolean
		{
			if( this.text == null || this.text.length == 0 )
			{
				return true;
			}

			var filterText:String = this.text.toLowerCase();
			var keep:Boolean = false;
			
			// Special items which are never filtered...
			if ( this._excludeFromFilter != null )
			{
				for each ( var excludedItem:Object in this._excludeFromFilter )
				{
					if ( excludedItem == item )
					{
						keep = true;
					}
				}
			}
			
			// Don't bother with this if we have already kept the file by virtue of 'excludeFromFilter'...
			if ( !keep )
			{
				// If proeprties are specified, ONLY filter on those properties...
				if ( this._filterProperties != null && this._filterProperties.length > 0 )
				{
					for each ( var property:String in this._filterProperties )
					{
						if ( item.hasOwnProperty( property ) && item[ property ] != null && item[ property ].toString().toLowerCase().indexOf( filterText ) != -1 )
						{
							keep = true;
							break;
						}
					}
				}
					// ...otherwise filter on every property we can find... 
				else
				{
					for ( property in item )
					{
						if ( item[ property ] != null && item[ property ].toString().toLowerCase().indexOf( filterText ) != -1 )
						{
							keep = true;
							break;
						}
					}
				}
			}
			
			return keep;
		}
	}
}
