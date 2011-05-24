
package com.ivt.flex.controls
{
	import com.ivt.flex.utils.SharedList;

	import flash.events.Event;
	import flash.events.FocusEvent;

	import flashx.textLayout.operations.CutOperation;
	import flashx.textLayout.operations.DeleteTextOperation;
	import flashx.textLayout.operations.FlowOperation;

	import mx.collections.ArrayCollection;
	import mx.collections.IList;
	import mx.core.mx_internal;
	import mx.states.State;

	import spark.components.ComboBox;
	import spark.events.DropDownEvent;
	import spark.events.IndexChangeEvent;
	import spark.events.TextOperationEvent;

	use namespace mx_internal;

	public class ComboBox extends spark.components.ComboBox
	{
		[SkinState("invalid")]
		[SkinState("customSelection")]

		private var _focused:Boolean = false;
		private var _allowCustomSelection:Boolean = true;
		private var _propertyField:String = "serial";
		private var _selectedProperty:Object = null;
		private var _selectedPropertyChanged:Boolean = false;
		private var _dataProviderChanged:Boolean = false;
		private var _matchType:String = "start";
		private var _matchingList:ArrayCollection = new ArrayCollection();
		private var _shrink:Boolean = true;
		private var _shrinkLimit:int = 1000;
		public  var sizeToFit:Boolean = false;

		public function ComboBox()
		{
			super();
			this.addEventListener( "dataProviderChanged", this.onDataProviderChange );
		}

		override public function set dataProvider( value:IList ):void
		{
			if( null != value )
			{
				var list:SharedList = new SharedList( value );
				list.filterFunction = this.filterList;
				super.dataProvider = list;
			}
			else
			{
				super.dataProvider = null;
			}
		}

		override protected function focusInHandler( event:FocusEvent ):void
		{
			this._focused = true;
			super.focusInHandler( event );
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

		[Inspectable(category="General", minValue="0", defaultValue="1000")]

		public function get shrinkLimit():int
		{
			return this._shrinkLimit;
		}

		public function set shrinkLimit( value:int ):void
		{
			this._shrinkLimit = value >= 0 ? value : 0;
		}

		override protected function getCurrentSkinState():String
		{
			if( this.selectedIndex == CUSTOM_SELECTED_ITEM && this.skin )
			{
				for each( var state:State in this.skin.states )
				{
					if( this._allowCustomSelection )
					{
						if( state.name == "customSelection" )
						{
							return "customSelection";
						}
					}
					else
					{
						if( state.name == "invalid" )
						{
							return "invalid";
						}
					}
				}
			}

			return super.getCurrentSkinState();
		}

		private function onDataProviderChange( event:Event = null ):void
		{
			this._dataProviderChanged = true;
			if( this.dataProvider )
			{
				this._matchingList = new ArrayCollection( (this.dataProvider as SharedList).source );
				this.findTypicalItem();
				this._shrink = (this.dataProvider as SharedList).source.length <= this._shrinkLimit;
			}
		}

		private function findTypicalItem():void
		{
			if( this.dataProvider )
			{
				var list:Array = (this.dataProvider as SharedList).source;
				// Setting 'typicalItem' to the longest item will cause the control to be sized accordingly
				if( this.sizeToFit )
				{
					var longestLength:int = 0;
					var longestItem:Object = null;

					for( var i:int = 0; i < list.length; i ++ )
					{
						var item:Object = list[ i ];
						if( null != item )
						{
							var label:String;
							if( item.hasOwnProperty( this.labelField ) )
							{
								label = item[ this.labelField ] as String;
							}
							else if( item is String )
							{
								label = item as String;
							}

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

// Selected property support

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
				// Give the dataProvider a chance to be set before the next frame, so that if we set selectedProperty
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
			if ( ( this._selectedPropertyChanged || this._dataProviderChanged ) && this.dataProvider != null && this._propertyField != null && this._selectedProperty != null )
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
						break;
					}
				}
			}
		}

		private function matchAnyPart( text:String ):void
		{
			var upperText:String = text.toUpperCase();
			var label:String;
			var index:int;
			var list:Array = (this.dataProvider as SharedList).source;
			var item:Object;

			for( var ii:int = 0; ii < list.length; ii++ )
			{
				item = list[ ii ];
				label = this.itemToLabel( list[ ii ] ).toUpperCase();
				index = label.indexOf( upperText );

				if( index >= 0 )
				{
					this._matchingList.addItem( item );
					if( !this._shrink )
					{
						return;
					}
				}
			}
		}

		private function matchStart( text:String ):void
		{
			var upperText:String = text.toUpperCase();
			var label:String;
			var list:Array = (this.dataProvider as SharedList).source;
			var item:Object;

			for( var ii:int = 0; ii < list.length; ii++ )
			{
				item = list[ ii ];
				label = this.itemToLabel( item ).toUpperCase();
				label = label.substring( 0, upperText.length );

				if( label == upperText )
				{
					this._matchingList.addItem( item );
					if( !this._shrink )
					{
						return;
					}
				}
			}
		}

		// Returns an array of possible values
		private function findMatchingItems(input:String):void
		{
			// For now, just select the first match
			this._matchingList = new ArrayCollection();

			switch( this._matchType )
			{
				case "anyPart":
					this.matchAnyPart( input );
					break;

				case "start":
				default:
					this.matchStart( input );
					break;
			}
		}

		private function processInputField( updateHighlight:Boolean = true ):void
		{
			if( !this.dataProvider || (this.dataProvider as SharedList).source.length <= 0 )
			{
                return;
			}

			if( this.textInput.text != "" )
			{
				if( this.itemMatchingFunction != null )
				{
					this._matchingList = this.itemMatchingFunction( this, this.textInput.text );
				}
				else
				{
					this.findMatchingItems( this.textInput.text );
				}

				if( this._matchingList.length > 0 )
				{
					if( this._shrink )
					{
						(this.dataProvider as SharedList).refresh();
					}

					if( updateHighlight )
					{
						var typedLength:int = this.textInput.text.length;
						//super.changeHighlightedSelection( this.dataProvider.getItemIndex( this._matchingList.getItemAt( 0 ) ), true );
						this.dropDownListBaseChangeHighlightedSelection( this.dataProvider.getItemIndex( this._matchingList.getItemAt( 0 ) ), true );
						if( this._matchingList.getItemAt( 0 ) && this.matchType == "start" )
						{
							// If we found a match, then replace the textInput text with the match and
							// select the non-typed characters
							var itemString:String = itemToLabel( this._matchingList.getItemAt( 0 ) );
							this.textInput.selectAll();
							this.textInput.insertText( itemString );
							this.textInput.selectRange( typedLength, itemString.length );
						}
					}
				}
				else
				{
					if( updateHighlight )
					{
						if( this._allowCustomSelection )
						{
							super.changeHighlightedSelection( CUSTOM_SELECTED_ITEM );
						}
						else
						{
							super.changeHighlightedSelection( NO_SELECTION );
						}
					}
				}
			}
			else
			{
				if( updateHighlight )
				{
					super.changeHighlightedSelection( NO_SELECTION );
				}
			}
		}

		override protected function textInput_changeHandler( event:TextOperationEvent ):void
		{
			var operation:FlowOperation = event.operation;

			// Close the dropDown if we press delete or cut the selected text
			if( operation is DeleteTextOperation || operation is CutOperation )
			{
				super.changeHighlightedSelection( CUSTOM_SELECTED_ITEM );
				this.processInputField( false );
			}
			else
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
		}

		private function editingOpenHandler( event:DropDownEvent ):void
		{
			this.removeEventListener( DropDownEvent.OPEN, this.editingOpenHandler );
			this.processInputField();
		}

		private function filterList( item:Object ):Boolean
		{
			if( this._matchingList )
			{
				return ( this._matchingList.getItemIndex( item ) != -1 );
			}
			return true;
		}

		// This is a copy of DropDownListBase.changeHighlightedSelection().
		// I've done this so I can skip past the ComboBox.changeHighlightedSelection() as it likes to do extra things such as select the typed text
		private function dropDownListBaseChangeHighlightedSelection( newIndex:int, scrollToTop:Boolean = false ):void
		{
			this.itemSelected( this.userProposedSelectedIndex, false );
			this.userProposedSelectedIndex = newIndex;
			this.itemSelected( this.userProposedSelectedIndex, true );
			this.positionIndexInView( this.userProposedSelectedIndex, scrollToTop ? 0 : NaN );

			var event:IndexChangeEvent = new IndexChangeEvent( IndexChangeEvent.CARET_CHANGE );
			event.oldIndex = this.caretIndex;
			this.setCurrentCaretIndex( this.userProposedSelectedIndex );
			event.newIndex = this.caretIndex;
			this.dispatchEvent( event );
		}

		override mx_internal function setSelectedIndex( value:int, dispatchChangeEvent:Boolean = false, changeCaret:Boolean = true ):void
		{
			if( this.dataProvider && value >= 0 )
			{
				// The list is filtered, we need to offset the index...
				if ( this.dataProvider.length < (this.dataProvider as SharedList).sourceList.length )
				{
					var item:* = this.dataProvider.getItemAt( value );
					value = (this.dataProvider as SharedList).sourceList.getItemIndex( item );
				}

				if( this._shrink )
				{
					this._matchingList.disableAutoUpdate();
					this._matchingList.source = (this.dataProvider as SharedList).source;
					this._matchingList.enableAutoUpdate();

					(this.dataProvider as SharedList).disableAutoUpdate();
					(this.dataProvider as SharedList).refresh();
					(this.dataProvider as SharedList).enableAutoUpdate();
				}

				// Trick the spark combobox into setting it's private 'actualProposedSelectedIndex' to the value we want
				this.userProposedSelectedIndex = value;
			}

			super.setSelectedIndex( value, dispatchChangeEvent );
		}
	}
}
