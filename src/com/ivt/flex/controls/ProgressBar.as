package com.ivt.flex.controls
{

	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.ProgressEvent;
	import flash.events.TimerEvent;
	import flash.utils.Timer;

	import mx.controls.ProgressBarMode;
	import mx.core.ILayoutElement;

	import spark.components.supportClasses.Range;
	import spark.components.supportClasses.TextBase;

	/**
	 * The colour of the progress bar.
	 * Will only mean something if the attached skin chooses to use this. 
	 */
	[Style(name="progressColour", type="Number", format="Color")]

	[DefaultBindingProperty(source="percentComplete")]

	/**
	 * Implementation of a component similar to the halo ProgressBar using the Spark skinning architecture.
	 * TODO: Indeterminate status. How would you skin this?
	 */
	public class ProgressBar extends Range
	{

		private var _label:String;

		private var _source:Object;
		private var _sourceChanged:Boolean;

		private var _mode:String;
		private var _modeChanged:Boolean;

		// Only used if _mode == poll
		private var _pollTimer:Timer;


		[SkinPart(required="false")]
		public var labelDisplay:TextBase;

		[SkinPart(required="true")]
		public var progressDisplay:ILayoutElement;

		public function ProgressBar()
		{
			super();
		}

		public function get percentComplete():Number { return this.value / this.maximum * 100; }
		public function get mode():String { return this._mode; }
		public function get label():String { return this._label; }
		public function get source():Object { return this._source; }

		/**
		 * Same as the halo ProgressBar.
		 * Use %1, %2, %3 and %% as placeholders for bytesLoaded, bytesTotal, percentComplete and a literal '%'
		 * respectively.
		 * @see mx.controls.ProgressBar#label
		 */
		public function set label( value:String ):void
		{
			this._label = value;
			invalidateDisplayList();
		}


		[Inspectable(enumeration="event,polled,manual")]
		
		/**
		 * @see mx.controls.ProgressBar#mode
		 */
		public function set mode( value:String ):void
		{
			this._mode = value;
			this._modeChanged = true;
			this.invalidateProperties();
		}

		/**
		 * @see mx.controls.ProgressBar#source
		 */
		public function set source( value:Object ):void
		{
			if ( this._source != null && this._source is EventDispatcher )
			{
				EventDispatcher( this._source ).removeEventListener( ProgressEvent.PROGRESS, this.onProgress );
				EventDispatcher( this._source ).removeEventListener( Event.COMPLETE, this.onProgressComplete );
			}

			this._source = value;
			this._sourceChanged = true;
			this.invalidateProperties();
		}

		/**
		 * @see mx.controls.ProgressBar#minimum
		 * @see spark.components.supportClasses.Range#minimum
		 */
		public override function set minimum( value:Number ):void
		{
			super.minimum = value;
			this.invalidateDisplayList();
		}

		/**
		 * @see mx.controls.ProgressBar#minimum
		 * @see spark.components.supportClasses.Range#minimum
		 */
		public override function set maximum( value:Number ):void
		{
			super.maximum = value;
			this.invalidateDisplayList();
		}

		/**
		 * This will be ignored unless the 'mode' is 'manual'
		 * @param value
		 * @param total
		 * @see mx.controls.ProgressBar#setProgress
		 */
		public function setProgress( value:Number, total:Number ):void
		{
			if ( this._mode == ProgressBarMode.MANUAL )
			{
				this.value = value;
				this.maximum = total;
				this.invalidateDisplayList();
			}
		}

		public override function invalidateProperties():void
		{
			super.invalidateProperties();

			if ( this._modeChanged || this._sourceChanged )
			{
				if ( this._mode == ProgressBarMode.EVENT && this._source != null && this._source is EventDispatcher )
				{
					EventDispatcher( this._source ).addEventListener( ProgressEvent.PROGRESS, this.onProgress );
					EventDispatcher( this._source ).addEventListener( Event.COMPLETE, this.onProgressComplete );
					this.killPollTimer();
				}
				else if ( this._mode == ProgressBarMode.MANUAL )
				{
					this.killPollTimer();
				}
				else if ( this._mode == ProgressBarMode.POLLED && this._source == null )
				{
					if ( this._pollTimer == null )
					{
						this._pollTimer = new Timer( 30 ); // Same as halo ProgressBar
						this._pollTimer.addEventListener( TimerEvent.TIMER, this.onPoll );
					}
					this._pollTimer.start();
				}

				this._modeChanged = false;
				this._sourceChanged = false;
			}

			if ( this._sourceChanged )
			{
				this._sourceChanged = false;
			}

		}

		/**
		 * Helper function which just stops the timer if it exists.
		 */
		private function killPollTimer():void
		{
			if ( this._pollTimer != null )
			{
				this._pollTimer.stop();
			}
		}

		private function onProgress( event:ProgressEvent ):void
		{
			this.value = event.bytesLoaded;
			this.maximum = event.bytesTotal;
			trace( event );
			this.invalidateDisplayList();
		}

		private function onProgressComplete( event:Event ):void
		{
			this.value = this.maximum;
			this.invalidateDisplayList();
		}

		/**
		 * Extract bytesLoaded and bytesTotal properties from the _source property and assign them to value and maximum
		 * properties of this object. This function is ignored if the properties don't exist on the source object.
		 * @param event
		 */
		private function onPoll( event:TimerEvent ):void
		{
			if ( this._source != null && this._source.hasOwnProperty( 'bytesLoaded' ) && this._source.hasOwnProperty( 'bytesTotal' ) )
			{
				this.value = this._source.bytesLoaded;
				this.maximum = this._source.bytesTotal;
				this.invalidateDisplayList();
			}
		}

		protected override function updateDisplayList( unscaledWidth:Number, unscaledHeight:Number ):void
		{
			super.updateDisplayList( unscaledWidth, unscaledHeight );

			if ( this.labelDisplay )
			{
				this.labelDisplay.text = this.createRealLabel();
			}

			if ( this.progressDisplay )
			{
				this.progressDisplay.percentWidth = this.percentComplete;
			}
		}

		/**
		 * Replace placeholders for the label.
		 * @return
		 */
		private function createRealLabel():String
		{
			var realValue:Number = Math.max( this.value, 0 );
			var realMaximum:Number = Math.max( this.maximum, 0 );
			var realLabel:String = this._label;

			realLabel = realLabel.replace( "%1", String( Math.floor( realValue ) ) );
			realLabel = realLabel.replace( "%2", String( Math.floor( realMaximum ) ) );
			realLabel = realLabel.replace( "%3", String( Math.floor( this.percentComplete ) ) );
			realLabel = realLabel.replace( "%%", "%" );

			return realLabel;
		}


	}

}
