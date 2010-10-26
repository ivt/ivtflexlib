package com.ivt.flex.utils
{
	
	import flash.events.*;
	import flash.net.*;
	import flash.utils.*;
	
	public class HelperUrl
	{
	
		private static var _urls:Array = new Array();
		private static var _timer:Timer;
		private static var _target:String = '_blank';
	
		/**
		 * Accepts an array of multiple UrlRequests/Strings and opens up a link for
		 * each of them. This is required because it seems that when you navigate to
		 * multiple URL's using the flash.net.navigateToUrl() function, it will only
		 * navigate to the final one.
		 */
		public static function navigateToMultipleUrls( urls:Array ):void
		{
			HelperUrl._target = '_blank';
			
			for each ( var url:Object in urls )
			{
				HelperUrl.navigateToUrl( url );
			}  
		}
	
		/**
		 * Safe navigateToUrl, because it is allowed to be called several times each 
		 * frame and will still open every URL, unlike the inbuilt function which 
		 * will only work on the final call in any given frame.
		 */	
		public static function navigateToUrl( url:Object, target:String = '_blank' ):void
		{
			var urlRequest:URLRequest;
			if ( url is String )
			{
				urlRequest = new URLRequest( url as String );
			}
			else if ( url is URLRequest )
			{
				urlRequest = url as URLRequest;
			}
			else
			{
				throw new Error( "'urls' must contain either URLRequests or Strings." );
			}
			
			HelperUrl._target = target;
			HelperUrl._urls.push( urlRequest );
			HelperUrl.init();
		}
	
		/**
		 * Ensures that we have a running timer.
		 * If a timer already exists, we don't need to create it, and if it is 
		 * alreaddy running, then we don't need to start it.
		 */	
		private static function init():void
		{
			if ( HelperUrl._timer == null )
			{
				HelperUrl._timer = new Timer( 50 );
				HelperUrl._timer.addEventListener( TimerEvent.TIMER, HelperUrl.onTimerTick );
			}
			
			if ( !HelperUrl._timer.running )
			{
				HelperUrl._timer.start();
			}
		}
		
		/**
		 * Each time the timer ticks over, we go to one more URL.
		 * Stop the timer when we reach the end to prevent CPU wastage.
		 */
		private static function onTimerTick( event:TimerEvent ):void
		{
			var url:URLRequest = HelperUrl._urls.shift();
			flash.net.navigateToURL( url, HelperUrl._target );

			// Keep going until there are no more URL's left...
			if ( _urls.length == 0 )
			{
				HelperUrl._timer.stop();
			}
		}
		
	}
}
