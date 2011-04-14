package com.ivt.flex.controls
{
	import flash.events.Event;
	import flash.events.FocusEvent;

	import mx.collections.ArrayCollection;
	import mx.collections.IList;
	import mx.collections.ListCollectionView;
	import mx.core.mx_internal;
	import mx.events.CollectionEvent;
	import mx.states.State;

	import spark.components.ComboBox;
	import spark.events.DropDownEvent;
	import spark.events.TextOperationEvent;

	use namespace mx_internal;

	public class ComboBox extends spark.components.ComboBox
	{
		[SkinState("invalid")]

		private var _focused:Boolean = false;
		private var _fullList:ArrayCollection;
		private var _matchingList:ArrayCollection = new ArrayCollection();
		private var _allowCustomSelection:Boolean = true;
		private var _matchType:String = "start";
		private var _propertyField:String = "serial";
		private var _selectedProperty:Object = null;
		private var _selectedPropertyChanged:Boolean = false;
		private var _dataProviderChanged:Boolean = false;
		public  var sizeToFit:Boolean = false;

		/**
		 * Lazily finds out the selected property based on the currently selected item.
		 * May not be the same as when you specified set selectedProperty.
		 * @return
		 */
		public function get selectedProperty():Object
		{
			if ( this._propertyField != null && this.selectedItem != null && this.selectedItem.hasOwnProperty( this._propertyField ) )
			{
				return this.selectedItem[ this._propertyField ];
			}
			else
			{
				return null;
			}
		}

		public function set selectedProperty( value:Object ):void
		{
			this._selectedProperty = value;
			this._selectedPropertyChanged = true;

			if ( this.dataProvider == null )
			{
				// Give the dataProvider a change to be set before the next frame, so that if we set selectedProperty
				// BEFORE dataProvider, we still work...
				this.invalidateProperties();
			}
			else
			{
				// Otherwise we can just force this now...
				this.commitSelectedProperty();
			}
		}

		public function get propertyField():String { return this._propertyField; }
		public function set propertyField( value:String ):void
		{
			this._propertyField = value;
			this.invalidateProperties();
		}

		/**
		 * Refactored outside of commitProperties, so that we can attempt to call it ourselves.
		 * This is because of some obscure and confusing behaviour which I *think* is related to invalidateProperties
		 * being called from within commitProperties. Maybe something to do with the singleton flex object responsible
		 * for invalidation...
		 */
		private function commitSelectedProperty():void
		{
			if ( ( this._selectedPropertyChanged || this._dataProviderChanged ) && this.dataProvider != null && this._propertyField != null )
			{
				if( this._selectedProperty != null )
				{
					this._selectedPropertyChanged = false;
					this._dataProviderChanged = false;
					for ( var i:int = 0; i < this.dataProvider.length; i ++ )
					{
						var item:Object = this.dataProvider.getItemAt( i );
						if ( item != null && item.hasOwnProperty( this._propertyField ) && item[ this._propertyField ] == this._selectedProperty )
						{
							this.selectedItem = item;
							this._selectedProperty = null;

							// Seems to work, but it didn't display the label for the selected item in some cases, so I will
							// help it along... Hope this doesn't bust any display stuff.
							this.updateLabelDisplay( item );
							return;
						}
					}
				}

				this.selectedIndex = NO_SELECTION;
				this.textInput.text = "";
			}
		}

		private function onDataProviderChange( event:Event = null ):void
		{
			this._dataProviderChanged = true;
			this.findTypicalItem();
		}

		private function findTypicalItem():void
		{
			if ( this.dataProvider )
			{
				// Setting 'typicalItem' to the longest item will cause the control to be sized accordingly
				if( this.sizeToFit )
				{
					var longestLength:int = 0;
					var longestItem:Object = null;

					for ( var i:int = 0; i < this.dataProvider.length; i ++ )
					{
						var item:Object = this.dataProvider.getItemAt( i );
						if( null != item && item.hasOwnProperty( this.labelField ) )
						{
							var label:String = item[ this.labelField ] as String;
							if( label && label.length >= longestLength )
							{
								longestLength = label.length;
								longestItem = item;
							}
						}
					}

					this.typicalItem = longestItem;
				}
			}
			else
			{
				this.typicalItem = null;
			}
		}

		public function ComboBox()
		{
			super();
			this.addEventListener( "dataProviderChanged", this.onDataProviderChange );
			this.addEventListener( CollectionEvent.COLLECTION_CHANGE, this.onDataProviderChange );
		}

		override protected function focusInHandler( event:FocusEvent ):void
		{
			this._focused = true;
			super.focusInHandler( event );
			this.invalidateSkinState();
		}

		override protected function focusOutHandler( event:FocusEvent ):void
		{
			this._focused = false;
			super.focusOutHandler( event );
		}

		[Inspectable(category="General")]

		public function get allowCustomSelection():Boolean
		{
			return this._allowCustomSelection;
		}

		public function set allowCustomSelection( value:Boolean ):void
		{
			this._allowCustomSelection = value;
		}

		[Inspectable(category="General", enumeration="start,anyPart", defaultValue="start")]

		public function get matchType():String
		{
			return this._matchType;
		}

		public function set matchType( value:String ):void
		{
			this._matchType = value;
		}

		private function reselectItem( item:Object ):void
		{
			this.restoreFullList();
			this.setSelectedItem( item );
		}

		private function restoreFullList():void
		{
			this._matchingList = this._fullList;
			if( this.dataProvider )
			{
				(this.dataProvider as ListCollectionView).refresh();
			}
		}

		private function filterList( item:Object ):Boolean
		{
			if( this._matchingList )
			{
				return ( this._matchingList.getItemIndex( item ) != -1 );
			}
			return true;
		}

		override protected function getCurrentSkinState():String
		{
			if( !this._allowCustomSelection && this.selectedIndex == CUSTOM_SELECTED_ITEM && this.skin && !this._focused )
			{
				for each( var state:State in this.skin.states )
				{
					if( state.name == "invalid" )
					{
						return "invalid";
					}
				}
			}

			return super.getCurrentSkinState();
		}

		override public function set dataProvider( value:IList ):void
		{
			if( null != value )
			{
				this._fullList = new ArrayCollection( value.toArray() );
				this._matchingList = new ArrayCollection( value.toArray() );
				var list:ListCollectionView = new ListCollectionView( value );
				list.filterFunction = this.filterList;
				list.refresh();
				super.dataProvider = list;
			}
			else
			{
				super.dataProvider = null;
			}
		}

		override mx_internal function applySelection():void
		{
			super.applySelection();
			this.invalidateSkinState();
			this.callLater( this.reselectItem, [ this.selectedItem ] );
		}

		override protected function commitProperties():void
		{
			var text:String = this.textInput.text;
			var anchor:int = this.textInput.selectionAnchorPosition;
			var active:int = this.textInput.selectionActivePosition;

			this.commitSelectedProperty();
			// Perform this AFTER we check the selectedProperty, because our code will potentially require validation of selectedIndex.
			super.commitProperties();

			// Restore the text, because we like it a lot.
			if( this.textInput.text.length == 0 && this.selectedIndex == NO_SELECTION )
			{
				this.textInput.text = text;
				this.textInput.selectRange( anchor, active );
			}
		}

		private function matchAnyPart( text:String ):Vector.<int>
		{
			var retVector:Vector.<int> = new Vector.<int>;
			var upperText:String = text.toUpperCase();
			var label:String;
			var index:int;

			for( var ii:int = 0; ii < this.dataProvider.length; ii++ )
			{
				label = this.itemToLabel( this.dataProvider.getItemAt( ii ) ).toUpperCase();
				index = label.indexOf( upperText );

				if( index >= 0 )
				{
					retVector.push( ii );
				}
			}

			return retVector;
		}

		private function matchStart( text:String ):Vector.<int>
		{
			var retVector:Vector.<int> = new Vector.<int>;
			var upperText:String = text.toUpperCase();
			var label:String;

			for( var ii:int = 0; ii < this.dataProvider.length; ii++ )
			{
				label = this.itemToLabel( this.dataProvider.getItemAt( ii ) ).toUpperCase();
				label = label.substring( 0, upperText.length );

				if( label == upperText )
				{
					retVector.push( ii );
				}
			}

			return retVector;
		}

		// Returns an array of possible values
		private function findMatchingItems(input:String):Vector.<int>
		{
			// For now, just select the first match
			var retVector:Vector.<int> = new Vector.<int>;

			switch( this._matchType )
			{
				case "anyPart":
					retVector = this.matchAnyPart( input );
					break;

				case "start":
				default:
					retVector = this.matchStart( input );
					break;
			}

			return retVector;
		}

		private function processInputField():void
		{
			var matchingItems:Vector.<int>;

			if( !this._fullList || this._fullList.length <= 0 )
			{
				return;
			}

			if( this.textInput.text != "" )
			{
				this.restoreFullList();

				if( this.itemMatchingFunction != null )
				{
					matchingItems = this.itemMatchingFunction( this, this.textInput.text );
				}
				else
				{
					matchingItems = this.findMatchingItems( this.textInput.text );
				}

				if (matchingItems.length > 0)
				{
					var object:Object = this._fullList.getItemAt( matchingItems[0] );

					this._matchingList = new ArrayCollection();
					for each( var index:int in matchingItems )
					{
						var item:Object = this._fullList.getItemAt( index );
						this._matchingList.addItem( item );
					}
					(this.dataProvider as ListCollectionView).refresh();

					super.changeHighlightedSelection( this.dataProvider.getItemIndex( object ), true );
				}
				else
				{
					this._matchingList = new ArrayCollection();
					(this.dataProvider as ListCollectionView).refresh();
					super.changeHighlightedSelection( CUSTOM_SELECTED_ITEM );
				}
			}
			else
			{
				this.restoreFullList();
				// If the input string is empty, then don't select anything
				super.changeHighlightedSelection(NO_SELECTION);
			}
		}

		override protected function textInput_changeHandler( event:TextOperationEvent ):void
		{
			if( this.openOnInput )
			{
				if( !this.isDropDownOpen )
				{
					// Open the dropDown if it isn't already open
					this.openDropDown();
					this.addEventListener( DropDownEvent.OPEN, this.editingOpenHandler );
					return;
				}
			}

			this.processInputField();
		}

		private function editingOpenHandler( event:DropDownEvent ):void
		{
			this.removeEventListener( DropDownEvent.OPEN, this.editingOpenHandler );
			this.processInputField();
		}
	}
}