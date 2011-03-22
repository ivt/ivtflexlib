package com.ivt.flex.collections
{

	import flash.events.Event;

	import mx.collections.ArrayCollection;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;

	public class LazyArrayCollection extends ArrayCollection
	{

		/**
		 * How many items to load each page that we go to the server.
		 */
		public var pageSize:Number = 10;

		private var _pageLoader:Class;

		private var _fullList:Array;
		private var _length:int;
		private var _pageLoaders:ArrayCollection = new ArrayCollection();
		private var _loadedCount:int = 0;

		public function LazyArrayCollection( length:int, pageLoader:Class )
		{
			this._pageLoader = pageLoader;
			this._length = length;
			this._fullList = new Array();
			for ( var i:int = 0; i < this._length; i ++ )
			{
				this._fullList.push( new PendingItem() );
			}
		}

		public override function get length():int { return this._length; }
		public override function get source():Array { return this._fullList; }

		public override function refresh():Boolean
		{
			// go to server and get things matching 'x'
			if ( filterFunction != null )
			{
				var tmp:Array = [];
				var len:int = localIndex.length;
				for (var i:int = 0; i < len; i++)
				{
					var item:Object = localIndex[i];
					if (filterFunction(item))
					{
						tmp.push(item);
					}
				}
				localIndex = tmp;
			}

			var refreshEvent:CollectionEvent = new CollectionEvent(CollectionEvent.COLLECTION_CHANGE);
			refreshEvent.kind = CollectionEventKind.REFRESH;
			dispatchEvent(refreshEvent);

			return false;
		}

		public override function getItemAt( index:int, prefetch:int = 0 ):Object
		{
			if ( _fullList[ index ] is PendingItem )
			{
				this.fillPage( index );
			}
			
			return this._fullList[ index ];
		}

		/**
		 * Take the item at startIndex, and fill a full page beginning with it.
		 * It doesn't matter if some of the items in front have already been loaded, they will be skipped once we
		 * get back from the server.
		 * @param startIndex
		 */
		private function fillPage( startIndex:Number ):void
		{
			if ( !this.isLoadingPage( startIndex ) )
			{
				var loader:IPageLoader = new _pageLoader();
				loader.addEventListener( Event.COMPLETE, this.onPageLoaded );
				loader.loadPage( startIndex, pageSize );
				this._pageLoaders.addItem( loader );
			}
		}

		private function isLoadingPage( startIndex:int ):Boolean
		{
			for each ( var loader:IPageLoader in this._pageLoaders )
			{
				if ( loader.startIndex <= startIndex && loader.startIndex + loader.pageSize >= startIndex )
				{
					return true;
				}
			}
			return false;
		}

		/**
		 * When the page has been loaded from the server, we look at the contents.
		 * We attempt to add each item to our list. If the item already has been loaded before because of a paging
		 * overlap, we ignore it.
		 * We also increment the total loaded count, so that at a particular point, we can jump forward and fill in
		 * the rest of the missing data.
		 * Finally, we dispatch a collection change (replace) event for each item, so that spark components will happily
		 * update their item renderers when new data is set.
		 */
		private function onPageLoaded( event:Event ):void
		{
			var loader:IPageLoader = ( event.target as IPageLoader );
			for ( var i:int = 0; i < loader.pageSize; i ++ )
			{
				var j:int = i + loader.startIndex;
				if ( this._fullList[ j ] is PendingItem )
				{
					this._fullList[ j ] = loader.data[ i ];
					this._loadedCount ++;
					this.dispatchEvent( new CollectionEvent( CollectionEvent.COLLECTION_CHANGE, false, false, CollectionEventKind.REPLACE, j, j, [ loader.data[ i ] ] ) );
				}
			}

			// Clean and remove the loader...
			loader.removeEventListener( Event.COMPLETE, this.onPageLoaded );
			var index:int = this._pageLoaders.getItemIndex( loader );
			if ( index != -1 )
			{
				this._pageLoaders.removeItemAt( index );
			}

			// Wait for the last page loader to go...
			if ( this._pageLoaders.length == 0 )
			{
				// Then check if we are almost completed loading.
				// If we are, then we can just shoot across to the server and get all remaining pages.
				// This will allow us to do filtering on local data rather than server data.
				if ( this._length - this._loadedCount < 100 )
				{
					// Identify all of the spots which need to be loaded.
					// If they are too sparse, then don't worry (e.g. we don't want to do 100 individual calls to the
					// server just because that is the distribution of the remaining items...
				}
			}
		}
	}

}

class PendingItem
{
	public function get label():String { return "Loading"; }
	public function toString():String { return this.label; }
}
