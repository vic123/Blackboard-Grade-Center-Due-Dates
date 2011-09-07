<bbNG:jsBlock>
    <script type="text/javascript">
        //this function is preserved from version 0.8, not used in v.0.9,
        //but common due time in user interface may become optional feature
        //in future releases
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

        //flag for allowing submit in confirmCancelIfDirty
        var action_is_post = false;
        //asssigned to forms' onsubmit event
        function onPostAction() {
            action_is_post = true;
        }

        //see comments for setSameTimeOnFormSubmit()
        var showTimePickerOnClick = null;
        var doNothingOnClick = null;
        //see comments for setSameTimeOnFormSubmit()
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

        //assigned to onbeforeunload event,
        //when field data get changed, field is assigned with 'dirty'
        //css class. Function is scanning all form elements for this class
        //and forces browser to ask confirmation for leaving of page with
        //unsaved modifications
        //!! Safari 4.0.1 does not invoke onbeforeunload event correctly
        //for multi-frame pages, Bb ones are multi-frame,
        //and therefore this functionality does not work for this browser.
        //http://stackoverflow.com/questions/4125068/window-onbeforeunload-but-for-a-frame
        //http://stackoverflow.com/questions/2253522/ie-onbeforeunload-not-firing-extenralinterface-callback
        function confirmCancelIfDirty (e) {
            if (action_is_post) return;
            e = e || window.event;

            var dataElements = document.getElementsByTagName('*');
            var isDirty = false;
            for ( var i = 0; i < dataElements.length; i++ ) {
              if ( dataElements[i].className.indexOf('dirty') >= 0 ) {
                isDirty = true;
                break;
              }
            }
            if (isDirty) {
                //confirm("Data was modified. Would you like to cancel changes? - confirm");
                //alert("Data was modified. Would you like to cancel changes? - alert");
                if (e) {
                    e.returnValue = 'Data was modified, would you like to cancel changes?';
                }
                return 'Data was modified, would you like to cancel changes?';
                //return false;
            } else {
                //return ""; //works for FireeFox 3.6-6 and IE 7-8, but fails in Safary 5.1
                //return null; fails in IE 9
                return; //no return value seem to work ok everywhere
            }
        }
        //universal function for assigning of event listener
        //can be replaced with more comprehenced code
        //(supporting browsers that allow only single event listener)
        //can be copied from here:
        //http://stackoverflow.com/questions/2253522/ie-onbeforeunload-not-firing-extenralinterface-callback
        function addListener(obj, evt, handler) {
            if (obj.addEventListener) {
                obj.addEventListener(evt, handler, false);
            } else if (obj.attachEvent) {
                obj.attachEvent('on' + evt, handler);
            }
        }

    //assignes confirmCancelIfDirty() to onbeforeunload diring initial page load
    addListener(window, 'beforeunload', confirmCancelIfDirty);

    </script>
</bbNG:jsBlock>	