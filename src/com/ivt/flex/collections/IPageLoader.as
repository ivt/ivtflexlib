package src
{

	import flash.events.IEventDispatcher;

	[Event(name="complete")]

	public interface IPageLoader extends IEventDispatcher
	{

		function loadPage( startIndex:int, pageSize:int ):void;
		function filterList( match:String ):void;

		function get data():Array;
		function get startIndex():int;
		function get pageSize():int;

	}

}
