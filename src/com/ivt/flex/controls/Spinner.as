package com.ivt.flex.controls
{
	import flash.display.Graphics;
	import flash.events.TimerEvent;
	import flash.utils.Timer;

	import mx.core.UIComponent;

	public class Spinner extends UIComponent
	{
		private static const TWOPI:Number = Math.PI * 2.0;
		protected var _timer:Timer;
		protected var _delay:Number = 100;
		protected var _currentTic:int = 0;
		protected var _tics:int;
		protected var _dAngle:Number;

		[Bindable]
		[Inspectable(category="General", format="Color")]
		public var color:uint = 0x000000;
		[Bindable]
		public var thickness:Number = 1.5;
		[Bindable]
		public var fade:Number = 0.1;
		[Bindable]
		public var innerRadiusRatio:Number = 0.5;

		public function Spinner()
		{
			super();

			this.tics = 10;
			this._timer = new Timer( this.delay );
			this._timer.addEventListener( TimerEvent.TIMER, this.onTimer );
		}

		[Bindable]
		public function get tics():int
		{
			return this._tics;
		}

		public function set tics( value:int ):void
		{
			if( this._tics == value )
			{
				return;
			}

			this._tics = value;
			this._dAngle = TWOPI / this._tics;
		}

		[Bindable]
		public function get delay():Number
		{
			return this._delay;
		}

		public function set delay( value:Number ):void
		{
			if( this._delay == value )
			{
				return;
			}

			this._delay = value;
			this._timer.delay = this._delay;
		}

		public function start():void
		{
			if( !this._timer.running )
			{
				this._timer.start();
			}
		}

		public function stop():void
		{
			if( this._timer.running )
			{
				this._timer.stop();
			}
		}

		override public function set visible( value:Boolean ):void
		{
			super.visible = value;
			if( value )
			{
				this.start();
			}
			else
			{
				this.stop();
			}
		}

		protected function onTimer( event:TimerEvent ):void
		{
			this._currentTic = (this._currentTic + 1) % this.tics;
			this.updateDisplayList( this.unscaledWidth, this.unscaledHeight );
		}

		override protected function updateDisplayList( unscaledWidth:Number, unscaledHeight:Number ):void
		{
			super.updateDisplayList( unscaledWidth, unscaledHeight );

			var g:Graphics = this.graphics;
			g.clear();
			this.draw( g, unscaledWidth, unscaledHeight );
		}

		protected function draw( g:Graphics, w:Number, h:Number ):void
		{
			var halfW:Number = Math.floor( w / 2 );
			var halfH:Number = Math.floor( h / 2 );
			var diameter:Number = Math.min( w, h );
			var radius:Number = Math.floor( diameter / 2 );
			var innerR:Number = Math.floor( radius * this.innerRadiusRatio );
			var angle:Number = 0;

			for( var ii:int = 0; ii < this.tics; ii++ )
			{
				var x:Number = halfW + (radius * Math.sin( angle ) );
				var y:Number = halfH - (radius * Math.cos( angle ) );

				var x2:Number = halfW + (innerR * Math.sin( angle ) );
				var y2:Number = halfH - (innerR * Math.cos( angle ) );

				var alpha:Number = 1.0 - ((ii + this._currentTic) % this.tics) * this.fade;
				alpha = Math.max( alpha, 0.0 );

				g.lineStyle( this.thickness, this.color, alpha, true );
				g.moveTo( x, y );
				g.lineTo( x2, y2 );

				angle -= this._dAngle;
			}
		}
	}
}
