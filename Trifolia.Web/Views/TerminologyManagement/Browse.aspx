﻿<%@ Page Title="" Language="C#" MasterPageFile="~/Views/Shared/Site.MVC.Master" Inherits="System.Web.Mvc.ViewPage<dynamic>" %>

<asp:Content ID="Content2" ContentPlaceHolderID="HeadContent" runat="server">
    <script type="text/javascript" src="/Scripts/TerminologyManagement/Browse.js?<%= ViewContext.Controller.GetType().Assembly.GetName().Version %>"></script>

    <style type="text/css">
        .table.identifiers tfoot tr td:not(:first-child) {
            padding-top: 28px;
            padding-bottom: 0px;
        }

        ul.dropdown-menu[template-url] {
            z-index: 1050;
        }

        ul.dropdown-menu[template-url] .row {
            padding: 2px 10px;
            cursor: pointer;
        }

        ul.dropdown-menu[template-url] .identifier-col {
            word-wrap: break-word;
        }

        .table.valueset-relationships thead tr th:nth-child(1),
        .table.valueset-relationships thead tr th:nth-child(2) {
            width: 25%;
        }

        .identifier-input-group {
            width: 100%;
        }

        .identifier-input-group input {
            border-bottom-right-radius: 4px !important;
            border-top-right-radius: 4px !important;
        }

        .identifier-removed,
        .identifier-removed input[type=text] {
            text-decoration: line-through;
        }
    </style>
</asp:Content>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="server">
    <div id="BrowseTerminology" class="ng-cloak" ng-app="Trifolia" ng-controller="BrowseTerminologyController">
        <h3>Browse Terminology</h3>

        <uib-tabset active="currentTab">
            <uib-tab heading="Value Sets" ng-if="showValueSets" select="tabChanged(0)">
                <div ng-controller="BrowseValueSetsController" ng-init="contextTabChanged()">
                    <form id="ValueSetSearchForm">
                        <div class="alert alert-info" ng-if="message">{{message}}</div>

                        <div class="input-group" style="padding-bottom: 10px;">
                            <input type="text" class="form-control" ng-model="criteria.query" />
                            <span class="input-group-btn">
                                <button class="btn btn-default" type="button" ng-click="criteria.query = ''; search(true);">
                                    <i class="glyphicon glyphicon-remove"></i>
                                </button>
                                <button class="btn btn-default" type="submit" ng-click="search(true)">Search</button>
                            </span>
                        </div>
                    </form>

                    <div class="row">
                        <div class="col-md-8">
                            <div ng-include="'valueSetPageNavigation'"></div>
                        </div>
                        <div class="col-md-4">
                            <div class="pull-right">
                                <div class="btn-group">
                                    <button type="button" class="btn btn-primary" ng-if="canEdit" ng-click="editValueSet()">Add Value Set</button>
                                    <button type="button" class="btn btn-primary" ng-click="openImportValueSet()">Import Value Set</button>
                                </div>
                            </div>
                        </div>
                    </div>

                    <table class="table table-striped">
                        <thead>
                            <tr>
                                <th ng-click="toggleSort('Name')" style="cursor: pointer;">
                                    Name
                                    <span ng-show="criteria.sort == 'Name'">
                                        <i ng-show="criteria.order == 'desc'" class="glyphicon glyphicon-chevron-down"></i>
                                        <i ng-show="criteria.order == 'asc'" class="glyphicon glyphicon-chevron-up"></i>
                                    </span>
                                </th>
                                <th ng-click="toggleSort('Identifiers')" style="cursor: pointer;">
                                    Identifier(s)
                                    <span ng-show="criteria.sort == 'Identifiers'">
                                        <i ng-show="criteria.order == 'desc'" class="glyphicon glyphicon-chevron-down"></i>
                                        <i ng-show="criteria.order == 'asc'" class="glyphicon glyphicon-chevron-up"></i>
                                    </span>
                                </th>
                                <th ng-click="toggleSort('IsComplete')" style="cursor: pointer;">
                                    Complete?
                                    <span ng-show="criteria.sort == 'IsComplete'">
                                        <i ng-show="criteria.order == 'desc'" class="glyphicon glyphicon-chevron-down"></i>
                                        <i ng-show="criteria.order == 'asc'" class="glyphicon glyphicon-chevron-up"></i>
                                    </span>
                                </th>
                                <th>Source</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr ng-repeat="r in searchResults.Items">
                                <td>
                                    <div class="dropdown">
                                        <a href="#" class="dropdown-toggle" role="menu" data-toggle="dropdown"><span>{{r.Name}}</span> <span class="caret"></span></a>
                                        <i ng-show="r.IsPublished" class="glyphicon glyphicon-exclamation-sign" title="This value set is used by a published implementation guide!"></i>
                                        <ul class="dropdown-menu">
                                            <li><a href="/TerminologyManagement/ValueSet/View/{{r.Id}}">View</a></li>
                                            <li ng-if="r.ImportSource"><a href="#" ng-click="openImportValueSet(r.ImportSource, r.ImportSourceId)">Re-import</a></li>
                                            <li ng-class="{ disabled: r.disableModify }"><a href="#" ng-click="editValueSet(r)" ng-disabled="r.disableModify">Edit Value Set</a></li>
                                            <li ng-class="{ disabled: r.disableModify }" ng-if="!r.ImportSource"><a href="/TerminologyManagement/ValueSet/Edit/{{r.Id}}/Concept" ng-disabled="r.disableModify">Edit Concepts</a></li>
                                            <li ng-class="{ disabled: r.disableModify }"><a href="#" ng-click="removeValueSet(r)" ng-disabled="r.disableModify">Remove</a></li>
                                        </ul>
                                    </div>
                                </td>
                                <td ng-bind-html="r.IdentifiersDisplay"></td>
                                <td>{{r.IsComplete ? 'Yes' : 'No'}}</td>
                                <td>
                                    <span ng-if="r.ImportSource" title="This value set has been imported from an external source. It cannot be edited, it can only be re-imported.">{{getImportSourceDisplay(r.ImportSource)}}</span>
                                    <span ng-if="!r.ImportSource">Trifolia</span>
                                </td>
                            </tr>
                        </tbody>
                        <tfoot>
                            <tr ng-if="isSearching">
                                <td colspan="3">Searching...</td>
                            </tr>
                            <tr ng-if="!isSearching && (!searchResults.Items || searchResults.Items.length == 0)">
                                <td colspan="3">No value sets found.</td>
                            </tr>
                        </tfoot>
                    </table>

                    <div ng-include="'valueSetPageNavigation'"></div>
                </div>
            </uib-tab>
            <uib-tab heading="Code Systems" ng-if="showCodeSystems" select="tabChanged(1)">
                <div ng-controller="BrowseCodeSystemsController" ng-init="contextTabChanged()">
                    <form id="CodeSystemSearchForm">
                        <div class="input-group" style="padding-bottom: 10px;">
                            <input type="text" class="form-control" ng-model="criteria.query" />
                            <span class="input-group-btn">
                                <button class="btn btn-default" type="button" ng-click="criteria.query = ''; search(true);">
                                    <i class="glyphicon glyphicon-remove"></i>
                                </button>
                                <button class="btn btn-default" type="submit" ng-click="search(true)">Search</button>
                            </span>
                        </div>
                    </form>
                
                    <div class="row">
                        <div class="col-md-8">
                            <div ng-include="'codeSystemPageNavigation'"></div>
                        </div>
                        <div class="col-md-4">
                            <div class="pull-right" ng-if="canEdit">
                                <button type="button" class="btn btn-primary" ng-click="editCodeSystem()">Add Code System</button>
                            </div>
                        </div>
                    </div>

                    <table class="table table-striped">
                        <thead>
                            <tr>
                                <th ng-click="toggleSort('Name')" style="cursor: pointer;">
                                    Name
                                    <span ng-show="criteria.sort == 'Name'">
                                        <i ng-show="criteria.order == 'desc'" class="glyphicon glyphicon-chevron-down"></i>
                                        <i ng-show="criteria.order == 'asc'" class="glyphicon glyphicon-chevron-up"></i>
                                    </span>
                                </th>
                                <th ng-click="toggleSort('Oid')" style="cursor: pointer;">
                                    Identifier
                                    <span ng-show="criteria.sort == 'Oid'">
                                        <i ng-show="criteria.order == 'desc'" class="glyphicon glyphicon-chevron-down"></i>
                                        <i ng-show="criteria.order == 'asc'" class="glyphicon glyphicon-chevron-up"></i>
                                    </span>
                                </th>
                                <th ng-click="toggleSort('MemberCount')" style="cursor: pointer;">
                                    #/Members
                                    <span ng-show="criteria.sort == 'MemberCount'">
                                        <i ng-show="criteria.order == 'desc'" class="glyphicon glyphicon-chevron-down"></i>
                                        <i ng-show="criteria.order == 'asc'" class="glyphicon glyphicon-chevron-up"></i>
                                    </span>
                                </th>
                                <th ng-click="toggleSort('ConstraintCount')" style="cursor: pointer;">
                                    #/Constraints
                                    <span ng-show="criteria.sort == 'ConstraintCount'">
                                        <i ng-show="criteria.order == 'desc'" class="glyphicon glyphicon-chevron-down"></i>
                                        <i ng-show="criteria.order == 'asc'" class="glyphicon glyphicon-chevron-up"></i>
                                    </span>
                                </th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr ng-repeat="r in searchResults.rows">
                                <td>
                                    <div class="dropdown">
                                        <a href="#" class="dropdown-toggle" role="menu" data-toggle="dropdown">{{r.Name}} <span class="caret"></span></a>
                                        <i ng-show="r.IsPublished" class="glyphicon glyphicon-exclamation-sign" title="This code system is used by a published implementation guide!"></i>
                                        <ul class="dropdown-menu">
                                            <li ng-disabled="r.disableModify"><a href="#" ng-click="editCodeSystem(r)">Edit</a></li>
                                            <li ng-disabled="r.disableModify"><a href="#" ng-click="removeCodeSystem(r)">Remove</a></li>
                                        </ul>
                                    </div>
                                </td>
                                <td>{{r.Oid}}</td>
                                <td>{{r.MemberCount}}</td>
                                <td>{{r.ConstraintCount}}</td>
                            </tr>
                        </tbody>
                        <tfoot>
                            <tr ng-if="isSearching">
                                <td colspan="3">Searching...</td>
                            </tr>
                            <tr ng-if="!isSearching && (!searchResults.rows || searchResults.rows.length == 0)">
                                <td colspan="3">No code systems found.</td>
                            </tr>
                        </tfoot>
                    </table>

                    <div ng-include="'codeSystemPageNavigation'"></div>
                </div>
            </uib-tab>
        </uib-tabset>

        <script type="text/html" id="valueSetTypeaheadTemplate.html">
            <div class="row">
                <div class="col-md-6">{{match.model.name}}</div>
                <div class="col-md-6 identifier-col">
                    <span ng-repeat="i in match.model.identifiers">{{i}}</span>
                </div>
            </div>
        </script>

        <script type="text/html" id="removeValueSetModal.html">
            <div class="modal-header">
                <h4 class="modal-title">Remove Value Set</h4>
            </div>
            <div class="modal-body" ng-init="init()">
                <div class="alert alert-warning">Removing the value set is a permanent action. If constraints are associated with the value set, please indicate which value set should replace it. The following table displays the relationships to the value set that will be affected by this change:</div>

                <table class="table table-striped valueset-relationships">
                    <thead>
                        <tr>
                            <th>Implementation Guide</th>
                            <th>Template/Profile</th>
                            <th>Constraint(s)</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr ng-repeat="r in relationships">
                            <td>{{r.ImplementationGuideName}}</td>
                            <td>
                                <span>{{r.TemplateName}}</span>
                                <sub>{{r.TemplateOid}}</sub>
                            </td>
                            <td>
                                <div class="row" ng-repeat="b in r.Bindings">
                                    <div class="col-md-4">{{b.ConstraintNumber}}</div>
                                    <div class="col-md-4">{{b.Date | date}}</div>
                                    <div class="col-md-4">{{(bindingStrengths | filter: { value: b.Strength })[0].display}}</div>
                                </div>
                            </td>
                        </tr>
                    </tbody>
                    <tfoot ng-show="relationships.length == 0">
                        <tr>
                            <td colspan="3">This value set does not have any relationships yet.</td>
                        </tr>
                    </tfoot>
                </table>

                <div class="form-group">
                    <label>Replacement value set</label>
                    <input type="text" class="form-control" placeholder="Type to search" typeahead-append-to-body="true" typeahead-template-url="valueSetTypeaheadTemplate.html" typeahead-show-hint="true" ng-model="replaceValueSet" typeahead-min-length="3" uib-typeahead="vs as vs.display for vs in searchValueSets($viewValue)"></input>
                </div>
            </div>
            <div class="modal-footer">
                <button type="submit" class="btn btn-primary" ng-disabled="isDisabled" ng-click="ok()">{{isDisabled ? 'Deleting Value Set, please wait...' : 'OK'}}</button>
                <button type="button" class="btn btn-default" ng-click="cancel()">Cancel</button>
            </div>
        </script>

        <script type="text/html" id="editValueSetModal.html">
            <form name="EditValueSetForm">
                <div class="modal-header">
                    <h4 class="modal-title">Edit Value Set</h4>
                </div>
                <div class="modal-body" style="max-height: 350px; overflow-y: scroll;" ng-init="init()">
                    <div class="form-group" ng-class="{ 'has-error': EditValueSetForm.name.$invalid }">
                        <label>Name</label>
                        <input type="text" class="form-control" name="name" ng-disabled="valueSet.ImportSource" ng-model="valueSet.Name" required maxlength="255" />
                        <span class="help-block" ng-show="EditValueSetForm.name.$error.required">Name is required</span>
                    </div>

                    <div class="panel panel-default panel-sm">
                        <div class="panel-heading">Identifiers</div>
                        <table class="table identifiers">
                            <thead>
                                <tr>
                                    <td>Type</td>
                                    <td>Identifier</td>
                                    <td>Default?</td>
                                    <td style="width: 50px;">
                                        <div class="pull-right">
                                            <button type="button" class="btn btn-default btn-sm" ng-click="addIdentifier()" title="Add a new identifier to the value set"><i class="glyphicon glyphicon-plus"></i></button>
                                        </div>
                                    </td>
                                </tr>
                            </thead>
                            <tbody ng-repeat="i in valueSet.Identifiers">
                                <tr ng-class="{ 'identifier-removed': i.ShouldRemove }">
                                    <td ng-class="{ 'has-error': i.$$typeError }">
                                        <select class="form-control" ng-disabled="valueSet.ImportSource && i.IsDefault" ng-options="o.value as o.display for o in getAvailableIdentifierTypes(i)" ng-model="i.Type" ng-disabled="i.ShouldRemove" ng-change="identifierChanged(i)"></select>
                                        <span class="help-block" ng-show="i.$$typeError">{{i.$$typeErrorMessage}}</span>
                                    </td>
                                    <td ng-class="{ 'has-error': i.$$valueError }">
                                        <input type="text" class="form-control" ng-disabled="valueSet.ImportSource && i.IsDefault" ng-model="i.Identifier" value-set-identifier ng-model-options="{ debounce: 500 }" ng-disabled="i.ShouldRemove" ng-change="identifierChanged(i)" />
                                        <span class="help-block" ng-show="i.$$valueError">{{i.$$valueErrorMessage}}</span>
                                    </td>
                                    <td>
                                        <input type="checkbox" ng-show="!i.IsRemoved" ng-disabled="valueSet.ImportSource" ng-model="i.IsDefault" ng-change="defaultIdentifierChanged(i)" ng-disabled="i.ShouldRemove" />
                                    </td>
                                    <td>
                                        <button type="button" class="btn btn-default btn-sm" ng-disabled="valueSet.ImportSource && i.IsDefault" ng-click="removeIdentifier(i)" ng-show="!i.ShouldRemove">
                                            <i class="glyphicon glyphicon-remove"></i>
                                        </button>
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                        
                    <div class="form-group">
                        <label>Code</label>
                        <input type="text" class="form-control" ng-disabled="valueSet.ImportSource" ng-model="valueSet.Code" maxlength="255" />
                    </div>
                        
                    <div class="form-group">
                        <label>Description</label>
                        <textarea class="form-control" ng-disabled="valueSet.ImportSource" ng-model="valueSet.Description" style="height: 50px;"></textarea>
                    </div>
                        
                    <div class="form-group">
                        <input type="checkbox" ng-disabled="valueSet.ImportSource" ng-model="valueSet.IsIntentional" />
                        <label>Intentional</label>
                    </div>
                        
                    <div class="form-group" ng-show="valueSet.IsIntentional">
                        <label for="valueSetIntentionalDefinition">Intentional Definition</label>
                        <textarea class="form-control" id="valueSetIntentionalDefinition" ng-disabled="valueSet.ImportSource" ng-model="valueSet.IntentionalDefinition"></textarea>
                    </div>
                        
                    <div class="form-group">
                        <input type="checkbox" ng-disabled="valueSet.ImportSource" ng-model="valueSet.IsComplete" />
                        <label>Complete?</label>
                        <span class="help-block">Indicates that the value set is defined completely in Trifolia, including all concepts.</span>
                    </div>
                        
                    <div class="form-group" ng-class="{ 'has-error': EditValueSetForm.sourceUrl.$invalid }">
                        <label>Source URL</label>
                        <input type="text" class="form-control" name="sourceUrl" ng-disabled="valueSet.ImportSource" ng-model="valueSet.SourceUrl" maxlength="255" ng-required="!valueSet.IsComplete" ng-pattern="urlRegex" />
                        <span class="help-block" ng-show="EditValueSetForm.sourceUrl.$error.required">Source URL is required when the value set is not complete.</span>
                        <span class="help-block" ng-show="EditValueSetForm.sourceUrl.$error.pattern">Source URL must be in the format of a URL (ex: http://www.google.com)</span>
                    </div>
                </div>
                <div class="modal-footer">
                    <span ng-if="!hasActiveIdentifier()">At least one valid identifier must be added to the value set.</span>
                    <button type="submit" class="btn btn-primary" ng-click="ok()" ng-disabled="EditValueSetForm.$invalid || !isValid()">OK</button>
                    <button type="button" class="btn btn-default" ng-click="cancel()">Cancel</button>
                </div>
            </form>
        </script>

        <script type="text/html" id="editCodeSystemModal.html">
            <form name="editCodeSystemForm">
                <div class="modal-header">
                    <h4 class="modal-title">Edit Code System</h4>
                </div>
                <div class="modal-body">
                    <div class="form-group">
                        <label for="codeSystemName">Name</label>
                        <input type="text" class="form-control" id="codeSystemName" ng-model="codeSystem.Name" name="name" required maxlength="255" />
                        <span class="help-block" ng-show="editCodeSystemForm.name.$error.required">Name is required.</span>
                    </div>
                        
                    <div class="form-group">
                        <label for="codeSystemOid">Identifier</label>
                        <input type="text" class="form-control" id="codeSystemOid" ng-model="codeSystem.Oid" name="identifier" ng-pattern="identifierRegex" required maxlength="255" ng-change="oidChanged()" />
                        <span class="help-block" ng-show="editCodeSystemForm.identifier.$error.pattern">The identifier is not in the correct format. Acceptable formats are: http(s)://XXX or urn:oid:XXX or urn:hl7ii:XXX:YYY</span>
                        <span class="help-block" ng-show="editCodeSystemForm.identifier.$error.required">Identifier is required.</span>
                        <span class="help-block" ng-show="oidIsDuplicate">The identifier specified is already in use by another code system.</span>
                    </div>
                        
                    <div class="form-group">
                        <label>Description</label>
                        <textarea class="form-control" style="height: 100px;" ng-model="codeSystem.Description" name="description"></textarea>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="submit" class="btn btn-primary" ng-click="ok()" ng-disabled="editCodeSystemForm.$invalid || oidIsDuplicate">OK</button>
                    <button type="button" class="btn btn-default" ng-click="cancel()">Cancel</button>
                </div>
            </form>
        </script>
        
        <script type="text/html" id="valueSetPageNavigation">
            Page {{criteria.page}} of {{totalPages}}, {{searchResults.TotalItems}} value sets
            <div class="btn-group btn-group-sm">
                <button type="button" class="btn btn-default btn-sm" ng-click="changePage('first')" ng-disabled="criteria.page <= 1" title="First Page">
                    <i class="glyphicon glyphicon-fast-backward"></i>
                </button>
                <button type="button" class="btn btn-default btn-sm" ng-click="changePage('previous')" ng-disabled="criteria.page <= 1" title="Previous Page">
                    <i class="glyphicon glyphicon-backward"></i>
                </button>
                <button type="button" class="btn btn-default btn-sm" ng-click="changePage('next')" ng-disabled="criteria.page >= totalPages" title="Next Page">
                    <i class="glyphicon glyphicon-forward"></i>
                </button>
                <button type="button" class="btn btn-default btn-sm" ng-click="changePage('last')" ng-disabled="criteria.page >= totalPages" title="Last Page">
                    <i class="glyphicon glyphicon-fast-forward"></i>
                </button>
                <button class="btn btn-default btn-sm dropdown-toggle" type="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="true">
                    {{criteria.rows}} per page
                    <span class="caret"></span>
                </button>
                <ul class="dropdown-menu">
                    <li><a href="#" ng-click="criteria.rows = 10; search();">10</a></li>
                    <li><a href="#" ng-click="criteria.rows = 20; search();">20</a></li>
                    <li><a href="#" ng-click="criteria.rows = 50; search();">50</a></li>
                    <li><a href="#" ng-click="criteria.rows = 100; search();">100</a></li>
                </ul>
            </div>
        </script>

        <script type="text/html" id="codeSystemPageNavigation">
            Page {{criteria.page}} of {{totalPages}}, {{searchResults.total}} code systems
            <div class="btn-group btn-group-sm">
                <button type="button" class="btn btn-default btn-sm" ng-click="changePage('first')" ng-disabled="criteria.page <= 1" title="First Page">
                    <i class="glyphicon glyphicon-fast-backward"></i>
                </button>
                <button type="button" class="btn btn-default btn-sm" ng-click="changePage('previous')" ng-disabled="criteria.page <= 1" title="Previous Page">
                    <i class="glyphicon glyphicon-backward"></i>
                </button>
                <button type="button" class="btn btn-default btn-sm" ng-click="changePage('next')" ng-disabled="criteria.page >= totalPages" title="Next Page">
                    <i class="glyphicon glyphicon-forward"></i>
                </button>
                <button type="button" class="btn btn-default btn-sm" ng-click="changePage('last')" ng-disabled="criteria.page >= totalPages" title="Last Page">
                    <i class="glyphicon glyphicon-fast-forward"></i>
                </button>
                <button class="btn btn-default btn-sm dropdown-toggle" type="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="true">
                    {{criteria.rows}} per page
                    <span class="caret"></span>
                </button>
                <ul class="dropdown-menu">
                    <li><a href="#" ng-click="criteria.rows = 10; search();">10</a></li>
                    <li><a href="#" ng-click="criteria.rows = 20; search();">20</a></li>
                    <li><a href="#" ng-click="criteria.rows = 50; search();">50</a></li>
                    <li><a href="#" ng-click="criteria.rows = 100; search();">100</a></li>
                </ul>
            </div>
        </script>

        <script type="text/html" id="importValueSetModal.html">
            <form>
                <div class="modal-header">
                    <h4 class="modal-title">Import Value Set</h4>
                </div>
                <div class="modal-body">
                    <div class="alert alert-info" ng-show="message" ng-bind-html="message"></div>
                    <div class="alert alert-info" ng-show="importing">Importing... Depending on the size of the value set being imported, this may take a while. Please be patient and do not refresh your browser until the import is done.</div>

                    <div class="form-group">
                        <label>Source</label>
                        <select ng-model="source" class="form-control" ng-disabled="disableSource">
                            <option ng-value="1" ng-if="canImportVSAC">VSAC</option>
                            <option ng-value="2" ng-if="canImportPHINVADS">PHIN VADS</option>
                        </select>
                    </div>

                    <div class="form-group">
                        <label for="codeSystemName">Identifier</label>
                        <input type="text" class="form-control" ng-model="id" required maxlength="255" ng-disabled="disableId" />
                        <span class="help-block" ng-show="!id">Identifier is required.</span>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="submit" class="btn btn-primary" ng-click="ok()" ng-disabled="!isValid() || importing">OK</button>
                    <button type="button" class="btn btn-default" ng-click="cancel()" ng-disabled="importing">Cancel</button>
                </div>
            </form>
        </script>
    </div>
</asp:Content>
