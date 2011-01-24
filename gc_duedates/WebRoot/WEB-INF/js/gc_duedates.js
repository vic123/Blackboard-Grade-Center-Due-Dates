<bbNG:jsBlock>
	<script type="text/javascript">
		function setSameTimeOnFormSubmit() {
			var common_time_check = document.getElementById("isCommonDueTimeParam");
			if (!common_time_check.checked) return;
			common_time_box = document.getElementById("tp_commonDueTimeParam_time");
			var str_common_time = common_time_box.value;
			if(calendar.TimePicker.timePickers.length > 0) {
					for (var index = 0; index < calendar.TimePicker.timePickers.length; index++) {
						var tp_item = calendar.TimePicker.timePickers[index];
						var str_tp_item_id = tp_item.inputTextElement.id;
						if (str_tp_item_id == "tp_commonDueTimeParam_time") continue;
						var str_hasdd_id = str_tp_item_id.replace("tp_liDueDateParam", "liHasDueDateParam_");
						str_hasdd_id = str_hasdd_id.replace ("_time", "");
						var hasdd_check = document.getElementById(str_hasdd_id);
						if (!hasdd_check.checked) continue;
						tp_item.inputTextElement.value = str_common_time;
					}
			}
		}
		
		var showTimePickerOnClick = null;
		var doNothingOnClick = null;
		
		function enableCommonDueTimeBox(commonTimeCheck) {
				for (var index = 0; index < calendar.TimePicker.timePickers.length; index++) {
					var tp_item = calendar.TimePicker.timePickers[index];
					var str_tp_item_id = tp_item.inputTextElement.id;
					if (str_tp_item_id != "tp_commonDueTimeParam_time") continue;
					else {
						tp_item.inputTextElement.disabled = !commonTimeCheck.checked;
						if (commonTimeCheck.checked) {
							if (showTimePickerOnClick == null) {
								showTimePickerOnClick = tp_item.showTimePicker.bindAsEventListener(tp_item); 
							}
							Event.observe(tp_item.tpImageLink, 'click', showTimePickerOnClick);			
							if (doNothingOnClick != null) {
								Event.stopObserving(tp_item.tpImageLink, 'click', doNothingOnClick);
							}
						} else {
							if (doNothingOnClick == null) {
								doNothingOnClick = tp_item.doNothing.bindAsEventListener(tp_item);
							}
							Event.observe(tp_item.tpImageLink, 'click', doNothingOnClick);
							if (showTimePickerOnClick != null) {
								Event.stopObserving(tp_item.tpImageLink, 'click', showTimePickerOnClick);
							}
						}
						break;
					}
				}
		}
	</script>
</bbNG:jsBlock>	