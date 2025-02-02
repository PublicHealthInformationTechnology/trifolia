﻿var handleAjaxError = function (msg) {
    return function (err, data, a1) {
        if (err && err.responseJSON) {
            console.log(msg + ': ' + err.responseJSON.Message);
        } else if (err && err.responseText) {
            console.log(msg + ': ' + err.responseText);
        } else {
            console.log(msg + ': ' + err);
        }
    }
};

var ContainerViewModel = function () {
    var self = this;

    self.Me = ko.observable();
    self.GroupDisclaimers = ko.observableArray([]);
    self.AccessRequests = ko.observable();

    var loadAccessRequests = function () {
        $.ajax({
            url: '/api/ImplementationGuide/RequestAuthorization/My',
            cache: false,
            success: function (results) {
                ko.mapping.fromJS({ AccessRequests: results }, {}, self);
            }
        });
    };

    self.OpenDisclaimers = function () {
        $('#GroupDisclaimersDialog').modal('show');
    };

    self.HasMyRequests = function () {
        if (!self.AccessRequests()) {
            return false;
        }

        return self.AccessRequests().MyRequests() && self.AccessRequests().MyRequests().length > 0;
    };

    self.HasApprovalRequests = function () {
        if (!self.AccessRequests()) {
            return false;
        }

        return self.AccessRequests().MyApprovals() && self.AccessRequests().MyApprovals().length > 0;
    };

    self.CompleteAccessRequest = function (accessRequest, approved) {
        var url = '/api/ImplementationGuide/RequestAuthorization/' + accessRequest.Id() + '/$complete?approved=' + approved;

        $.ajax({
            url: url,
            method: 'POST',
            success: function () {
                alert('Request ' + approved ? 'approved' : 'denied');
                loadAccessRequests();
            }
        });
    };

    self.ShowAccessRequests = function () {
        $("#accessRequestsDialog").modal('show');
    };

    self.Initialize = function () {
        $(document).ajaxError(function (event, jqXHR, settings, thrownError) {
            if (jqXHR.responseJSON && jqXHR.responseJSON.ExceptionMessage) {
                console.log(jqXHR.responseJSON.ExceptionMessage);
                alert(jqXHR.responseJSON.ExceptionMessage);
            } else {
                console.log(jqXHR.responseText);
                //alert("An error occurred while processing the request");
            }
        });

        $.ajax({
            url: '/api/Auth/WhoAmI',
            cache: false,
            async: false,
            success: function (results) {
                ko.mapping.fromJS({ Me: results }, {}, self);
            },
            error: function (err) {
                alert('An error occurred while identifying who the current user is');
            }
        });

        $.ajax({
            url: '/api/Group/My/Disclaimer',
            cache: false,
            success: function (results) {
                ko.mapping.fromJS({ GroupDisclaimers: results }, {}, self);
            },
            error: function (err) {
                alert('An error occurred while getting disclaimers associated with the current user');
            }
        });

        loadAccessRequests();
    };

    self.DisplayName = ko.computed(function () {
        if (!self.Me()) {
            return 'Log In';
        }

        return self.Me().Name();
    });

    self.DisplayToolTip = ko.computed(function () {
        if (!self.Me()) {
            return '';
        }

        return self.Me().UserName();
    });

    self.HasSecurable = function (securableNames) {
        if (!self.Me()) {
            return false;
        }

        for (var securableNameIndex in securableNames) {
            var securableName = securableNames[securableNameIndex];

            var foundSecurable = ko.utils.arrayFirst(self.Me().Securables(), function (securable) {
                return securable === securableName;
            });

            if (foundSecurable)
                return true;
        }

        return false;
    };

    self.Initialize();
};