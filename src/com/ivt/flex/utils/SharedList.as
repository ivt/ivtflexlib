package com.ivt.flex.utils
{
	import mx.collections.ArrayCollection;
	import mx.collections.ArrayList;
	import mx.collections.IList;
	import mx.events.CollectionEvent;

	public class SharedList extends ArrayCollection
	{
		private var _sourceList:IList;

		public function SharedList( source:IList = null )
		{
			this.sourceList = source;
		}

		public function set sourceList( value:IList ):void
		{
			if( this._sourceList != null )
			{
				this._sourceList.removeEventListener( CollectionEvent.COLLECTION_CHANGE, this.onSourceListChanged );
			}

			this._sourceList = value;

			if( this._sourceList != null )
			{
				this._sourceList.addEventListener( CollectionEvent.COLLECTION_CHANGE, this.onSourceListChanged );
			}

			this.updateSourceProperty();
		}

		private function updateSourceProperty():void
		{
			if ( this._sourceList == null )
			{
				this.source = null;
			}
			else
			{
				if( this._sourceList is ArrayCollection )
				{
					this.source = (this._sourceList as ArrayCollection).source;
				}
				else if( this._sourceList is ArrayList )
				{
					this.source = (this._sourceList as ArrayList).source;
				}
				else
				{
					this.source = this._sourceList.toArray();
				}
			}
			this.refresh();
		}

		private function onSourceListChanged( event:CollectionEvent ):void
		{
			this.updateSourceProperty();
		}
	}
}
