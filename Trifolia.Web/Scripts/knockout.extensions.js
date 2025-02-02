﻿(function ($) {
    $.each(['show', 'hide'], function (i, ev) {
        var el = $.fn[ev];
        $.fn[ev] = function () {
            this.trigger(ev);
            return el.apply(this, arguments);
        };
    });
})(jQuery);

var GenericCombo = function (valueField, textField) {
    var self = this;
    var initializing = true;

    var calculateWidth = function (element, allBindings) {
        var width = allBindings().width || $(element).attr('width') || $(element).width();
        var eleWidth = width;

        if (width.toString().indexOf('%', width.toString().length - 1) !== -1) {
            var parentWidth = $(parent).width();
            eleWidth = (parentWidth / parseInt(width.substring(0, width.length - 1))) * 100;
        }

        return eleWidth;
    };
    
    self.Initializing = true;
    self.GetData = null;
    self.ValidValue = null;
    self.ValueType = 'string';
    self.DisplayFormatter = function (row) {
        return row[self.TextField];
    };
    self.TypeAheadFilter = function (q, row) {
        return row[self.TextField] && row[self.TextField].toLowerCase().indexOf(q.toLowerCase()) >= 0;
    };
    self.ValueField = valueField ? valueField : 'value';
    self.TextField = textField ? textField : 'text';
    
    self.Binding = {
        init: function (element, valueAccessor, allBindings) {
            var value = valueAccessor();
            var comboDisabled = typeof (allBindings().comboDisabled) !== 'undefined' ? allBindings().comboDisabled : null;
            var comboEditable = typeof (allBindings().comboEditable) !== 'undefined' ? allBindings().comboEditable : true;
            var onChange = typeof (allBindings().onChange) !== 'undefined' ? allBindings().onChange : null;
            var requireSelection = typeof (allBindings().requireSelection) !== 'undefined' ? allBindings().requireSelection : true;
            var valueType = typeof (allBindings().valueType) !== 'undefined' ? allBindings().valueType : self.ValueType;
            var comboDisabledVal = false;

            if (!valueType) {
                valueType = self.ValueType;
            }

            if (typeof (comboDisabled) === 'function') {
                comboDisabledVal = comboDisabled();

                comboDisabled.subscribe(function (newComboDisabledVal) {
                    var setValue = typeof (value()) !== 'undefined' && value() != null ? value().toString() : '';
                    /*$(element).combobox({
                        disabled: newComboDisabledVal,
                        value: setValue
                    });*/
                });
            } else if (typeof (comboDisabled) == 'object') {
                comboDisabledVal = comboDisabled;
            }
            
            /*
            $(element).combobox({
                valueField: self.ValueField,
                textField: self.TextField,
                width: calculateWidth(element, allBindings),
                disabled: comboDisabledVal,
                formatter: self.DisplayFormatter,
                filter: self.TypeAheadFilter,
                editable: comboEditable,
                onChange: function (newValue) {
                    var data = $(element).combobox('getData');
                    var foundItem = false;

                    if (value() == newValue) {
                        return;
                    }

                    if (self.ValidValue && !self.ValidValue(newValue)) {
                        return;
                    }

                    if (requireSelection) {
                        for (var i in data) {
                            if (data[i][self.ValueField] == newValue) {
                                foundItem = data[i];
                            }
                        }
                    } else {
                        foundItem = true;
                    }

                    if (foundItem) {
                        if (valueType == 'int') {
                            newValue = parseInt(newValue);

                            if (isNaN(newValue)) {
                                newValue = '';
                            }
                        } else if (valueType == 'boolean') {
                            if (newValue == 'true' || newValue == 'True') {
                                newValue = true;
                            } else {
                                newValue = false;
                            }
                        }

                        value(newValue);

                        if (onChange) {
                            onChange(newValue, foundItem);
                        }
                    } else {
                        value('');

                        if (onChange) {
                            onChange('');
                        }
                    }
                }
            });
            */
            
            $(parent).on('resize', function () {
                if ($(element).is(':visible')) {
                    var newWidth = calculateWidth(element, allBindings);
                    //$(element).combobox('resize', newWidth);
                }
            });

            if (self.GetData) {
                self.GetData(element, valueAccessor, allBindings, function (data) {
                    /*
                    $(element).combobox({
                        data: data
                    });
                    */

                    var setValue = typeof (value()) !== 'undefined' && value() != null ? value().toString() : '';
                    //$(element).combobox('setValue', setValue);

                    self.Initializing = false;
                });
            } else {
                var setValue = typeof (value()) !== 'undefined' && value() != null ? value().toString() : '';
                //$(element).combobox('setValue', setValue);

                self.Initializing = false;
            }
        },
        update: function (element, valueAccessor) {
            if (self.Initializing) {
                return;
            }

            var value = valueAccessor();

            if (typeof (value()) !== 'undefined' && value() != null) {
                //$(element).combobox('setValue', value().toString());
            }
        }
    };
};

/* Simple Combo */
var combo = new GenericCombo();
ko.bindingHandlers.combo = combo.Binding;

/* Data Grid */
ko.bindingHandlers.datagrid = {
    init: function (element, valueAccessor, allBindingsAccessor, viewModel, bindingContext) {
        var bindings = allBindingsAccessor();
        var ignoreSubscription = false;

        $(element).datagrid({
            onSelect: function (rowIndex, rowData, arg1, arg2, arg3) {
                var rowId = null;
                eval("rowId = rowData." + bindings.itemId + ";");

                ignoreSubscription = true;

                if (bindings.selectedIndex && ko.isObservable(bindings.selectedIndex)) {
                    bindings.selectedIndex(rowIndex);
                }

                if (bindings.selectedItemId && ko.isObservable(bindings.selectedItemId) && bindings.itemId) {
                    bindings.selectedItemId(rowId);
                }

                ignoreSubscription = false;
            }
        });

        if (bindings.selectedItemId && ko.isObservable(bindings.selectedItemId) && bindings.itemId) {
            bindings.selectedItemId.subscribe(function (newSelectedItemId) {
                if (!ignoreSubscription) {
                    if (newSelectedItemId) {
                        $(element).datagrid("selectRecord", newSelectedItemId);
                    } else {
                        $(element).datagrid("unselectAll");
                    }
                }
            });
        }

        if (bindings.selectedIndex && ko.isObservable(bindings.selectedIndex)) {
            bindings.selectedIndex.subscribe(function (newSelectedIndex) {
                if (!ignoreSubscription) {
                    if (newSelectedIndex && newSelectedIndex >= 0) {
                        $(element).datagrid("selectRow", newSelectedIndex);
                    } else {
                        $(element).datagrid("unselectAll");
                    }
                }
            });
        }
    },
    update: function (element, valueAccessor, allBindingsAccessor, viewModel, bindingContext) {
        var value = valueAccessor();
        var valueUnwrapped = value();

        $(element).datagrid({
            data: ko.toJS(valueUnwrapped)
        });
    }
};

/* Date */
ko.bindingHandlers.date = {
    init: function (element, valueAccessor, allBindings) {
        var value = valueAccessor();
        var allBindingsAccessor = allBindings();

        var options = allBindingsAccessor.dateOptions || {
            format: 'mm/dd/yyyy',
            todayBtn: 'linked',
            autoclose: true,
            todayHighlight: true
        };

        $(element).datepicker(options)
            .on('changeDate', function (ev) {
                var date = ev.date.getDate();
                var month = ev.date.getMonth() + 1; //Months are zero based
                var year = ev.date.getFullYear();

                $(element).attr('isUpdating', true);
                value(month + '/' + date + '/' + year);
                $(element).removeAttr('isUpdating');
            })
            .on('clearDate', function (ev) {
                $(element).attr('isUpdating', true);
                value('');
                $(element).removeAttr('isUpdating');
            });

        if (value()) {
            var valueMoment = moment(value());
            $(element).datepicker('update', valueMoment.format('MM/DD/YYYY'));
        } else {
            $(element).datepicker('update', value());
        }

        /*
        $(element).change(function () {
            var newVal = $(element).val();

            if (!newVal) {
                value(null);
            }
        });
        */
    },
    update: function (element, valueAccessor) {
        var value = valueAccessor();

        if ($(element).attr('isUpdating') === "true") {
            return;
        }

        if (value()) {
            var valueMoment = moment(value());
            $(element).datepicker('update', valueMoment.format('MM/DD/YYYY'));
        } else {
            $(element).datepicker('update', value());
        }
    }
};

/* Dialog */
ko.bindingHandlers.dialog = {
    init: function (element, valueAccessor, allBindingsAccessor) {
        var options = ko.utils.unwrapObservable(valueAccessor()) || {};
        //do in a setTimeout, so the applyBindings doesn't bind twice from element being copied and moved to bottom
        setTimeout(function () {
            options.close = function () {
                allBindingsAccessor().dialogVisible(false);
            };

            $(element).dialog(options);
        }, 0);

        //handle disposal (not strictly necessary in this scenario)
        ko.utils.domNodeDisposal.addDisposeCallback(element, function () {
            $(element).dialog("destroy");
        });
    },
    update: function (element, valueAccessor, allBindingsAccessor) {
        var shouldBeOpen = ko.utils.unwrapObservable(allBindingsAccessor().dialogVisible),
            $el = $(element),
            dialog = $el.data("uiDialog") || $el.data("dialog");

        //don't call open/close before initilization
        if (dialog) {
            $el.dialog(shouldBeOpen ? "open" : "close");
        }
    }
};

/* File */
ko.bindingHandlers.file = {
    init: function (element, valueAccessor) {
        $(element).change(function () {
            var file = this.files[0];
            if (ko.isObservable(valueAccessor())) {
                valueAccessor()(file);
            }
        });
    },

    update: function (element, valueAccessor, allBindingsAccessor) {
        var file = ko.utils.unwrapObservable(valueAccessor());
        var bindings = allBindingsAccessor();

        if (bindings.fileBinaryData && ko.isObservable(bindings.fileBinaryData)) {
            if (!file) {
                bindings.fileBinaryData(null);
            } else {
                var reader = new FileReader();
                reader.onload = function (e) {
                    var result = e.target.result || {};
                    var resultParts = result.split(',');

                    if (resultParts.length === 2) {
                        bindings.fileBinaryData(resultParts[1]);
                    }

                    if (bindings.fileObjectURL && ko.isObservable(bindings.fileObjectURL)) {
                        var oldUrl = bindings.fileObjectURL();
                        if (oldUrl) {
                            window.URL.revokeObjectURL(oldUrl);
                        }
                        bindings.fileObjectURL(file && window.URL.createObjectURL(file));
                    }
                };
                reader.readAsDataURL(file);
            }
        }
    }
};

ko.validation.makeBindingHandlerValidatable("file");

/* subscribeChanged */
ko.subscribable.fn.subscribeChanged = function (callback) {
    var oldValue;
    this.subscribe(function (_oldValue) {
        oldValue = _oldValue;
    }, this, 'beforeChange');

    this.subscribe(function (newValue) {
        callback(newValue, oldValue);
    });
};

/* helpContext */
ko.bindingHandlers.helpContext = {
    init: function (element, valueAccessor) {
        var helpContextId = valueAccessor();
        $(element).helpContext(helpContextId);
    }
};

/* helpTooltip */
ko.bindingHandlers.helpTooltip = {
    init: function (element, valueAccessor) {
        var options = valueAccessor() || {};

        if (typeof options.trigger === "undefined") {
            options.trigger = "click";
        }

        $(element)
            .addClass("glyphicon")
            .addClass("glyphicon-question-sign")
            .addClass("clickable")
            .tooltip(options);
    }
};

/* Highlight */
ko.bindingHandlers.highlight = {
    init: function (element, valueAccessor) {
        var highlightText = valueAccessor();

        if (highlightText && highlightText()) {
            setTimeout(function () {
                $(element).highlight(highlightText());
            });
        }

        if (typeof highlightText === 'function') {
            highlightText.subscribe(function (newVal, oldVal) {
                $(element).unhighlight();

                if (newVal) {
                    $(element).highlight(newVal);
                }
            });
        }
    }
};

/* Hint */
ko.bindingHandlers.hint = {
    init: function (element, valueAccessor, allBindingsAccessor, viewModel, bindingContext) {
        var valueUnwrapped = ko.utils.unwrapObservable(valueAccessor());
        $(element).attr('title', valueUnwrapped);
        $(element).hint();
    },
};

/* isDirty */
ko.dirtyFlag = function (root) {
    var self = this;

    var result = function () { },
        _initialState = ko.observable(ko.toJSON(root)),
        _isDirty = ko.observable(false);

    result.isDirty = ko.computed(function () {
        if (_initialState() !== ko.toJSON(root)) {
            _isDirty(true);
        }

        return _isDirty();
    });

    result.reset = function () {
        _initialState(ko.toJSON(root));
        _isDirty(false);
    };

    return result;
};

/* Localization */
ko.bindingHandlers.localizationContext = {
    init: function (element, valueAccessor, allBindings, viewModel, bindingContext) {
        element.localizationContext = valueAccessor();
    }
};

ko.bindingHandlers.localization = {
    init: function (element, valueAccessor, allBindings, viewModel, bindingContext) {
        var getContext = function () {
            var current = element;
            var context = element.localizationContext;

            while (current && !context) {
                context = current.localizationContext;
                current = current.parentNode;
            }

            return context;
        };

        var context = typeof (allBindings().localizationContext) !== 'undefined' ? allBindings().localizationContext : getContext();
        var localizationBindings = valueAccessor();

        if (!context) {
            console.log("Could not find context for localization binding");
            return;
        }

        for (var i in localizationBindings) {
            var currentLocalizationBinding = localizationBindings[i];

            if (!context[currentLocalizationBinding]) {
                console.log("Could not find localization property in context for " + currentLocalizationBinding);
                continue;
            }

            if (i === 'title') {
                $(element).attr('title', context[currentLocalizationBinding]);
            } else if (i === 'html') {
                $(element).html(context[currentLocalizationBinding]);
            }
        }
    }
};

/* spinedit */
ko.bindingHandlers.spinedit = {
    init: function (element, valueAccessor, allBindingsAccessor) {
        var value = valueAccessor();
        var allBindings = allBindingsAccessor();
        var options = allBindings.spineditOptions || {};
        var treatZeroAsNull = allBindings.treatZeroAsNull || false;

        if (typeof options.maximum === 'undefined') {
            options.maximum = 10000000;     // 10 million
        }

        $(element)
            .spinedit(options)
            .on("valueChanged", function (e) {
                if (e.value == 0 && treatZeroAsNull) {
                    value(null);
                } else {
                    value(e.value);
                }
            });
    },
    update: function (element, valueAccessor, allBindingsAccessor) {
        var value = valueAccessor();
        $(element).spinedit('setValue', value());
    }
};

/* templateWithOtions: TODO: Remove? Not used? */
ko.virtualElements.allowedBindings.templateWithOptions = true;

ko.bindingHandlers.templateWithOptions = {
    init: ko.bindingHandlers.template.init,
    update: function (element, valueAccessor, allBindingsAccessor, viewModel, context) {
        var options = ko.utils.unwrapObservable(valueAccessor());
        //if options were passed attach them to $data
        if (options.templateOptions) {
            context.$templateOptions = ko.utils.unwrapObservable(options.templateOptions);
        }
        //call actual template binding
        ko.bindingHandlers.template.update(element, valueAccessor, allBindingsAccessor, viewModel, context);
        //clean up
        delete context.$data.$item;
    }
}

/* Tooltip */
ko.bindingHandlers.tooltip = {
    init: function (element, valueAccessor, allBindingsAccessor, viewModel, bindingContext) {
        var value = valueAccessor();
        var valueUnwrapped = ko.utils.unwrapObservable(valueAccessor());
        $(element).attr('title', valueUnwrapped);
        $(element).tooltip();

        if (typeof value === 'function' && value.subscribe) {
            value.subscribe(function (newValue) {
                $(element).attr('title', newValue);
                $(element).tooltip();
            });
        }
    },
};

/* SimpleMDE */
ko.bindingHandlers.markdown = {
    init: function (element, valueAccessor, allBindingsAccessor, viewModel, bindingContext) {
        var value = valueAccessor();
        var valueUnwrapped = ko.utils.unwrapObservable(valueAccessor());
        var allBindings = allBindingsAccessor();
        var validTags = ['p', 'b', 'i', 'em', 'a', 'ul', 'ol', 'li', 'table', 'thead', 'tbody', 'tr', 'td', 'th', 'span', 'strong', 'cite'];
        var implementationGuideId;

        if (allBindings.implementationGuideId) {
            if (typeof allBindings.implementationGuideId === 'function') {
                implementationGuideId = allBindings.implementationGuideId();
                allBindings.implementationGuideId.subscribe(function () {
                    implementationGuideId = allBindings.implementationGuideId();
                });
            } else {
                implementationGuideId = allBindings.implementationGuideId;
            }
        }

        var checkHTML = function (html) {
            var doc = document.createElement('div');
            doc.innerHTML = html;
            var foundElements = $(doc).find('*');
            var invalidTags = _.filter(foundElements, function (foundElement) {
                return foundElement.localName === 'invalid' || validTags.indexOf(foundElement.localName.toLowerCase()) < 0;
            });

            var results = {
                // Validate that all tags are properly closed
                validHTML: (doc.innerHTML.toLowerCase() === html.toLowerCase()),

                // Validate that the markdown only contains tags supported by Trifolia
                validTags: invalidTags.length == 0
            };

            return results;
        };

        var prettyPrintXmlToolbar = {
            name: 'pretty-print-xml',
            action: function (editor) {
                var selectedText = editor.codemirror.getSelection();

                if (!selectedText) {
                    return;
                }

                var singleTickRegex = /^`(.+?)`$/g;
                var multiTickRegex = /^```(.+?)```$/g;
                if (multiTickRegex.test(selectedText)) {
                    var formattedText = vkbeautify.xml(selectedText.substring(3, selectedText.length - 3));
                    var replaceText = '`' + formattedText + '`';
                    if (replaceText.indexOf('\n') > 0) {
                        replaceText = '```' + formattedText + '```';
                    }
                    editor.codemirror.replaceSelection(replaceText);
                } else if (singleTickRegex.test(selectedText)) {
                    var formattedText = vkbeautify.xml(selectedText.substring(1, selectedText.length - 1));
                    var replaceText = '`' + formattedText + '`';
                    if (replaceText.indexOf('\n') > 0) {
                        replaceText = '```' + formattedText + '```';
                    }
                    editor.codemirror.replaceSelection(replaceText);
                } else {
                    var formattedText = vkbeautify.xml(selectedText);
                    editor.codemirror.replaceSelection(formattedText);
                }
            },
            className: 'fa fa-terminal',
            title: 'Pretty print XML'
        };

        var trifoliaHelpToolbar = {
            name: 'trifolia-help',
            action: function (editor) {
                window.open('/Help/FormattingText.html', '_new');
            },
            className: 'fa fa-question-circle',
            title: 'Formatting guide'
        };

        var igImageToolbar = {
            name: 'ig-image',
            action: function (editor) {
                var toolbarDiv = editor.toolbarElements['ig-image'];
                var foundPopover = $(toolbarDiv).find('.ig-image-popover');
                var imageElements = '';

                if (foundPopover.length == 0) {
                    var popoverDiv = '<div class="ig-image-popover" data-toggle="popover" title="Insert images from this IG"></div>';
                    $(toolbarDiv).append(popoverDiv);
                    $(toolbarDiv).find('.ig-image-popover').popover({
                        html: true,
                        container: $(editor.gui.toolbar).parent()[0],
                        content: function () {
                            return imageElements;
                        }
                    });
                }

                var baseIgUrl = '/api/ImplementationGuide/' + implementationGuideId;

                $.get(baseIgUrl + '/Images', function (images) {
                    imageElements = '';

                    _.each(images, function (image) {
                        imageElements += '<a href="#" class="ig-image-popover-entry" img-description="' + image.Description + '">' + image.FileName + '</a><br/>';
                    });

                    $(toolbarDiv).find('.ig-image-popover').popover('toggle');

                    $(editor.gui.toolbar).parent().find('.popover-content a').on('click', function (e) {
                        var doc = editor.codemirror.getDoc();
                        var cursor = doc.getCursor();
                        var description = $(e.target).attr('img-description');
                        var fileurl = (baseIgUrl + '/Image/' + e.target.innerHTML).replace(/ /g, '%20');
                        doc.replaceRange('![' + (description || filename) + '](' + fileurl + ')', cursor);
                    });
                });
            },
            className: 'fa fa-star',
            title: 'Image from IG'
        };

        var simplemde;
        var validateTimeout = null;
        var options = {
            element: element,
            initialValue: valueUnwrapped || '',
            toolbar: [
                'bold', 'italic', 'strikethrough', 'heading',
                '|',
                'code', prettyPrintXmlToolbar, 'quote', 'unordered-list', 'ordered-list',
                '|',
                'link', 'image', igImageToolbar, 'table',
                '|',
                'preview', 'fullscreen', trifoliaHelpToolbar],
            status: [{
                className: "validation",
                onUpdate: function (el) {
                    if (validateTimeout) {
                        clearTimeout(validateTimeout);
                        validateTimeout = null;
                    }

                    // Only validate once every half-second
                    validateTimeout = setTimeout(function () {
                        if (!simplemde) {
                            return;
                        }
                        var data = simplemde.value();
                        var validationResults = checkHTML(data);
                        if (!validationResults.validHTML) {
                            el.innerHTML = 'Markdown contains incorrectly formatted HTML which may not be rendered correctly in exports. Ensure all tags are closed.';
                        } else if (!validationResults.validTags) {
                            el.innerHTML = 'Markdown contains XML/HTML tags that will not be formatted properly during export. Consider escaping custom HTML/XML.'
                        } else {
                            el.innerHTML = '';
                        }
                    }, 500);
                }
            }, "autosave", "lines", "words", "cursor"]
        };

        if (!implementationGuideId) {
            var igImageToolbarIndex = options.toolbar.indexOf(igImageToolbar);
            options.toolbar.splice(igImageToolbarIndex, 1);
        }

        if (allBindings.limitedToolbar) {
            options.toolbar = ["bold", "italic", "strikethrough", "link", "|", "preview", "fullscreen", "guide"];
        }

        simplemde = new SimpleMDE(options);

        if (allBindings.disable) {
            function setSimplemdeDisabled(disabled) {
                simplemde.codemirror.options.readOnly = disabled;
                simplemde.codemirror.display.disabled = disabled;

                if (disabled) {
                    $(simplemde.gui.toolbar).hide();
                } else {
                    $(simplemde.gui.toolbar).show();
                }

                $(simplemde.gui.toolbar).next().toggleClass('disabled', disabled);
            }

            if (typeof allBindings.disable === 'function') {
                setSimplemdeDisabled(allBindings.disable());

                if (allBindings.disable.subscribe) {
                    allBindings.disable.subscribe(function () {
                        setSimplemdeDisabled(allBindings.disable());
                    });
                }
            } else {
                setSimplemdeDisabled(allBindings.disable);
            }
        }

        // If the markdown plugin is being loaded in a modal window, 
        // perform a short delay for setting the initial value
        // to avoid the bug where the text area doesn't actually show any value
        if ($(element).parents('.modal').length > 0) {
            setTimeout(function () {
                simplemde.value(valueUnwrapped);
            }, 500);
        }

        var watchValueSubscription = null;
        var watchValue = function () {
            if (typeof value === 'function' && value.subscribe) {
                watchValueSubscription = value.subscribe(function (newValue) {
                    simplemde.value(newValue);
                });
            }
        }

        simplemde.codemirror.on("change", function () {
            if (watchValueSubscription) {
                watchValueSubscription.dispose();       // remove the subscription
                watchValueSubscription = null;
            }
            value(simplemde.value());
            watchValue();                       // re-add the subscription
        });

        watchValue();

        ko.utils.domNodeDisposal.addDisposeCallback(element, function () {
            simplemde.toTextArea();
            simplemde = null;
        });
    }
};