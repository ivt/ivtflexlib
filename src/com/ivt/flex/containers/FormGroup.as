package com.ivt.flex.containers
{

	import spark.components.Group;

	/**
	 * A group for use within a FormItem.
	 * All it does is return the baselinePosition of the first element within itself when asked for its own
	 * baseline position. This will prevent any funky aligning issues with the form label.
	 */
	public class FormGroup extends Group
	{

		public function FormGroup()
		{
			super();
		}

		override public function get baselinePosition():Number
		{
			if( this.numElements > 0 )
			{
				return this.getElementAt( 0 ).baselinePosition;
			}
			return super.baselinePosition;
		}
	}

}
