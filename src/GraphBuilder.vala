/*
* Copyright (c) 2018 David Hewitt (https://github.com/davidmhewitt)
*
* This file is part of Vala Cycle Detector (VCD)
*
* VCD is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* VCD is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with VCD.  If not, see <http://www.gnu.org/licenses/>.
*/

public class GraphBuilder : Vala.CodeVisitor {
    Gvc.Context graph_context;
    Gvc.Graph graph;

    private Gee.HashMap<Vala.Class, Gvc.Node?> nodes_map;
    private Gee.HashMultiMap<Gvc.Node, Gvc.Node> edges_map;

    private bool nodes_gathered = false;

    public GraphBuilder (Vala.CodeContext context) {
        nodes_map = new Gee.HashMap<Vala.Class, Gvc.Node?> ();
        edges_map = new Gee.HashMultiMap<Gvc.Node, Gvc.Node> ();

        graph_context = new Gvc.Context ();
        graph = new Gvc.Graph ("code", Gvc.Agdirected);

        // Gather nodes
        context.accept (this);
        nodes_gathered = true;

        // Generate edges
        context.accept (this);

        graph_context.layout (graph, "dot");
        graph_context.render (graph, "dot", stdout);
    }

    public override void visit_source_file (Vala.SourceFile file) {
        file.accept_children (this);
    }

    public override void visit_addressof_expression (Vala.AddressofExpression expr) {
        expr.accept_children (this);
    }

    public override void visit_array_creation_expression (Vala.ArrayCreationExpression expr) {
        expr.accept_children (this);
    }

    public override void visit_assignment (Vala.Assignment a) {
        a.accept_children (this);
    }

    public override void visit_base_access (Vala.BaseAccess expr) {
        expr.accept_children (this);
    }

    public override void visit_binary_expression (Vala.BinaryExpression expr) {
        expr.accept_children (this);
    }

    public override void visit_block (Vala.Block b) {
        b.accept_children (this);
    }

    public override void visit_boolean_literal (Vala.BooleanLiteral lit) {
        lit.accept_children (this);
    }

    public override void visit_break_statement (Vala.BreakStatement stmt) {
        stmt.accept_children (this);
    }

    public override void visit_cast_expression (Vala.CastExpression expr) {
        expr.accept_children (this);
    }

    public override void visit_catch_clause (Vala.CatchClause clause) {
        clause.accept_children (this);
    }

    public override void visit_character_literal (Vala.CharacterLiteral lit) {
        lit.accept_children (this);
    }

    public override void visit_class (Vala.Class cl) {
        cl.accept_children (this);

        if (nodes_gathered) {
            return;
        }

        if (!nodes_map.has_key (cl)) {
            nodes_map[cl] = null;
            //nodes_map[cl] = graph.create_node (cl.name);
        }
    }

    public override void visit_conditional_expression (Vala.ConditionalExpression expr) {
        expr.accept_children (this);
    }

    public override void visit_constant (Vala.Constant c) {
        c.accept_children (this);
    }

    public override void visit_constructor (Vala.Constructor c) {
        c.accept_children (this);
    }

    public override void visit_continue_statement (Vala.ContinueStatement stmt) {
        stmt.accept_children (this);
    }

    public override void visit_creation_method (Vala.CreationMethod m) {
        m.accept_children (this);
    }

    public override void visit_declaration_statement (Vala.DeclarationStatement stmt) {
        stmt.accept_children (this);
    }

    public override void visit_delegate (Vala.Delegate cb) {
        cb.accept_children (this);
    }

    public override void visit_delete_statement (Vala.DeleteStatement stmt) {
        stmt.accept_children (this);
    }

    public override void visit_do_statement (Vala.DoStatement stmt) {
        stmt.accept_children (this);
    }

    public override void visit_element_access (Vala.ElementAccess expr) {
        expr.accept_children (this);
    }

    public override void visit_empty_statement (Vala.EmptyStatement stmt) {
        stmt.accept_children (this);
    }

    public override void visit_enum (Vala.Enum en) {
        en.accept_children (this);
    }

    public override void visit_error_domain (Vala.ErrorDomain edomain) {
        edomain.accept_children (this);
    }

    public override void visit_expression_statement (Vala.ExpressionStatement stmt) {
        stmt.accept_children (this);
    }

    public override void visit_field (Vala.Field f) {
        f.accept_children (this);
        if (!nodes_gathered) {
            return;
        }

        if (f.variable_type.is_weak () || !f.variable_type.value_owned) {
            return;
        }

        if (f.variable_type.to_string ().has_prefix ("GLib.")) {
            return;
        }

        if (f.variable_type.to_string () == "string") {
            return;
        }

        if (f.parent_symbol is Vala.Class) {
            var parent_class = f.parent_symbol as Vala.Class;
#if VALA_0_48
            if (f.variable_type is Vala.ObjectType && f.variable_type.type_symbol is Vala.Class) {
                var to_class = f.variable_type.type_symbol as Vala.Class;
#else
            if (f.variable_type is Vala.ObjectType && f.variable_type.data_type is Vala.Class) {
                var to_class = f.variable_type.data_type as Vala.Class;
#endif

                if (to_class.base_class != null) {
                    add_pair (parent_class, to_class.base_class);
                }

                if (f.variable_type.has_type_arguments ()) {
                    if (to_class.name.contains ("List") || to_class.name.contains ("Map") || to_class.name.contains ("Set")) {
                        foreach (var arg in f.variable_type.get_type_arguments ()) {
#if VALA_0_48
                            if (arg.type_symbol is Vala.Class) {
                                add_pair (parent_class, arg.type_symbol as Vala.Class);
                            }
#else
                            if (arg.data_type is Vala.Class) {
                                add_pair (parent_class, arg.data_type as Vala.Class);
                            }
#endif
                        }
                    }
                }

                add_pair (parent_class, to_class);
            }
        }
    }

    private Gee.ArrayList<Vala.Class> get_parent_references (Vala.Class toplevel) {
        var list = new Gee.ArrayList<Vala.Class> ();
        foreach (var f in toplevel.get_fields ()) {
            if (f.variable_type.is_weak () || !f.variable_type.value_owned) {
                continue;
            }

            if (f.variable_type.to_string ().has_prefix ("GLib.")) {
                continue;
            }

            if (f.variable_type.to_string () == "string") {
                continue;
            }

            if (f.parent_symbol is Vala.Class) {
                var parent_class = f.parent_symbol as Vala.Class;
#if VALA_0_48
                if (f.variable_type is Vala.ObjectType && f.variable_type.type_symbol is Vala.Class) {
                    var to_class = f.variable_type.type_symbol as Vala.Class;
#else
                if (f.variable_type is Vala.ObjectType && f.variable_type.data_type is Vala.Class) {
                    var to_class = f.variable_type.data_type as Vala.Class;
#endif
                    if (f.variable_type.has_type_arguments ()) {
                        if (to_class.name.contains ("List") || to_class.name.contains ("Map") || to_class.name.contains ("Set")) {
                            foreach (var arg in f.variable_type.get_type_arguments ()) {
#if VALA_0_48
                                if (arg.type_symbol is Vala.Class) {
                                    list.add (arg.type_symbol as Vala.Class);
                                }
#else
                                if (arg.data_type is Vala.Class) {
                                    list.add (arg.data_type as Vala.Class);
                                }
#endif
                            }
                        }
                    }

                    list.add (to_class);
                }
            }
        }

        foreach (var prop in toplevel.get_properties ()) {
            if (prop.property_type.is_weak () || !prop.property_type.value_owned) {
                continue;
            }

            if (prop.property_type.to_string ().has_prefix ("GLib.")) {
                continue;
            }

            if (prop.property_type.to_string () == "string") {
                continue;
            }

            if (prop.parent_symbol is Vala.Class) {
                var parent_class = prop.parent_symbol as Vala.Class;
#if VALA_0_48
                if (prop.property_type is Vala.ObjectType && prop.property_type.type_symbol is Vala.Class) {
                    var to_class = prop.property_type.type_symbol as Vala.Class;
#else
                if (prop.property_type is Vala.ObjectType && prop.property_type.data_type is Vala.Class) {
                    var to_class = prop.property_type.data_type as Vala.Class;
#endif
                    if (prop.property_type.has_type_arguments ()) {
                        if (to_class.name.contains ("List") || to_class.name.contains ("Map") || to_class.name.contains ("Set")) {
                            foreach (var arg in prop.property_type.get_type_arguments ()) {
#if VALA_0_48
                                if (arg.type_symbol is Vala.Class) {
                                    list.add (arg.type_symbol as Vala.Class);
                                }
#else
                                if (arg.data_type is Vala.Class) {
                                    list.add (arg.data_type as Vala.Class);
                                }
#endif
                            }
                        }
                    }

                    list.add (to_class);
                }
            }
        }

        if (toplevel.base_class != null) {
            list.add_all (get_parent_references (toplevel.base_class));
        }

        return list;
    }

    public override void visit_for_statement (Vala.ForStatement stmt) {
        stmt.accept_children (this);
    }

    public override void visit_foreach_statement (Vala.ForeachStatement stmt) {
        stmt.accept_children (this);
    }

    public override void visit_if_statement (Vala.IfStatement stmt) {
        stmt.accept_children (this);
    }

    public override void visit_initializer_list (Vala.InitializerList list) {
        list.accept_children (this);
    }

    public override void visit_integer_literal (Vala.IntegerLiteral lit) {
        lit.accept_children (this);
    }

    public override void visit_interface (Vala.Interface iface) {
        iface.accept_children (this);
    }

    public override void visit_lambda_expression (Vala.LambdaExpression expr) {
        expr.accept_children (this);
    }

    public override void visit_local_variable (Vala.LocalVariable local) {
        local.accept_children (this);
    }

    public override void visit_lock_statement (Vala.LockStatement stmt) {
        stmt.accept_children (this);
    }

    public override void visit_loop (Vala.Loop stmt) {
        stmt.accept_children (this);
    }

    public override void visit_member_access (Vala.MemberAccess expr) {
        expr.accept_children (this);
    }

    public override void visit_method (Vala.Method m) {
        m.accept_children (this);
    }

    public override void visit_method_call (Vala.MethodCall expr) {
        expr.accept_children (this);
    }

    public override void visit_namespace (Vala.Namespace ns) {
        ns.accept_children (this);
    }

    public override void visit_null_literal (Vala.NullLiteral lit) {
        lit.accept_children (this);
    }

    public override void visit_object_creation_expression (Vala.ObjectCreationExpression expr) {
        expr.accept_children (this);
    }

    public override void visit_pointer_indirection (Vala.PointerIndirection expr) {
        expr.accept_children (this);
    }

    public override void visit_postfix_expression (Vala.PostfixExpression expr) {
        expr.accept_children (this);
    }

    public override void visit_property (Vala.Property prop) {
        prop.accept_children (this);

        if (!nodes_gathered) {
            return;
        }

        if (prop.property_type.is_weak () || !prop.property_type.value_owned) {
            return;
        }

        if (prop.property_type.to_string ().has_prefix ("GLib.")) {
            return;
        }

        if (prop.property_type.to_string () == "string") {
            return;
        }

        if (prop.parent_symbol is Vala.Class) {
            var parent_class = prop.parent_symbol as Vala.Class;
#if VALA_0_48
            if (prop.property_type is Vala.ObjectType && prop.property_type.type_symbol is Vala.Class) {
                var to_class = prop.property_type.type_symbol as Vala.Class;
#else
            if (prop.property_type is Vala.ObjectType && prop.property_type.data_type is Vala.Class) {
                var to_class = prop.property_type.data_type as Vala.Class;
#endif

                if (to_class.base_class != null) {
                    add_pair (parent_class, to_class.base_class);
                }

                if (prop.property_type.has_type_arguments ()) {
                    if (to_class.name.contains ("List") || to_class.name.contains ("Map") || to_class.name.contains ("Set")) {
                        foreach (var arg in prop.property_type.get_type_arguments ()) {
#if VALA_0_48
                            if (arg.type_symbol is Vala.Class) {
                                add_pair (parent_class, arg.type_symbol as Vala.Class);
                            }
#else
                            if (arg.data_type is Vala.Class) {
                                add_pair (parent_class, arg.data_type as Vala.Class);
                            }
#endif
                        }
                    }
                }

                add_pair (parent_class, to_class);
            }
        }
    }

    private void add_pair (Vala.Class from, Vala.Class to) {
        if (nodes_map.has_key (from) && nodes_map.has_key (to)) {
            if (nodes_map[from] == null) {
                nodes_map[from] = graph.create_node (from.get_full_name ());
            }

            if (nodes_map[to] == null) {
                nodes_map[to] = graph.create_node (to.get_full_name ());
            }

            var from_node = nodes_map[from];
            var to_node = nodes_map[to];
            create_edge (from_node, to_node);
        }
    }

    private void create_edge (Gvc.Node from, Gvc.Node to) {
        if (!edges_map.contains (from) || !(to in edges_map.@get (from))) {
            graph.create_edge (from, to);
            edges_map.@set (from, to);
        }
    }

    public override void visit_real_literal (Vala.RealLiteral lit) {
        lit.accept_children (this);
    }

    public override void visit_reference_transfer_expression (Vala.ReferenceTransferExpression expr) {
        expr.accept_children (this);
    }

    public override void visit_return_statement (Vala.ReturnStatement stmt) {
        stmt.accept_children (this);
    }

    public override void visit_signal (Vala.Signal sig) {
        sig.accept_children (this);
    }

    public override void visit_sizeof_expression (Vala.SizeofExpression expr) {
        expr.accept_children (this);
    }

    public override void visit_slice_expression (Vala.SliceExpression expr) {
        expr.accept_children (this);
    }

    public override void visit_string_literal (Vala.StringLiteral lit) {
        lit.accept_children (this);
    }

    public override void visit_struct (Vala.Struct st) {
        st.accept_children (this);
    }

    public override void visit_switch_label (Vala.SwitchLabel label) {
        label.accept_children (this);
    }

    public override void visit_switch_section (Vala.SwitchSection section) {
        section.accept_children (this);
    }

    public override void visit_switch_statement (Vala.SwitchStatement stmt) {
        stmt.accept_children (this);
    }

    public override void visit_throw_statement (Vala.ThrowStatement stmt) {
        stmt.accept_children (this);
    }

    public override void visit_try_statement (Vala.TryStatement stmt) {
        stmt.accept_children (this);
    }

    public override void visit_type_check (Vala.TypeCheck expr) {
        expr.accept_children (this);
    }
}
