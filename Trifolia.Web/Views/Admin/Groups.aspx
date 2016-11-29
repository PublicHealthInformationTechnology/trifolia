﻿<%@ Page Title="" Language="C#" MasterPageFile="~/Views/Shared/Site.MVC.Master" Inherits="System.Web.Mvc.ViewPage<Trifolia.Web.Models.RoleManagement.RolesModel>" %>

<asp:Content ID="Content2" ContentPlaceHolderID="HeadContent" runat="server">
    <style type="text/css">
        #Roles .row {
            padding-top: 5px;
        }
    </style>
</asp:Content>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">

    <div id="Groups">
        <h2>Groups</h2>

        <div class="table-responsive">
            <table class="table table-striped">
                <thead>
                    <tr>
                        <th>Name</th>
                        <th></th>
                    </tr>
                </thead>
                <tbody data-bind="foreach: Groups">
                    <tr>
                        <td data-bind="text: Name"></td>
                        <td>
                            <div class="pull-right">
                                <div class="btn-group">
                                    <a class="btn btn-primary" data-bind="attr: { href: '/Admin/Group/' + Id }">Edit</a>
                                    <button type="button" class="btn btn-default" data-bind="click: function () { $root.DeleteGroup($data); }">Delete</button>
                                </div>
                            </div>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>

    <script type="text/javascript" src="/Scripts/Admin/Groups.js?<%= ViewContext.Controller.GetType().Assembly.GetName().Version %>"></script>
    <script type="text/javascript">
        var viewModel = null;
        $(document).ready(function () {
            viewModel = new GroupsViewModel();
            ko.applyBindings(viewModel, $('#Groups')[0]);
        });
    </script>

</asp:Content>