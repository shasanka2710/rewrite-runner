package org.example;

import org.openrewrite.*;
import org.openrewrite.xml.XmlIsoVisitor;
import org.openrewrite.xml.tree.Xml;
import org.openrewrite.java.tree.J;
import org.openrewrite.java.JavaIsoVisitor;
import org.openrewrite.marker.Markers;

import java.util.Arrays;

public class CustomTldAndJspMigrationRecipe extends Recipe {

    @Override
    public String getDisplayName() {
        return "Custom TLD and JSP Migration";
    }

    @Override
    public String getDescription() {
        return "Update legacy JSP taglib URIs and refactor obsolete scriptlets.";
    }

    @Override
    public TreeVisitor<?, ExecutionContext> getVisitor() {
        return new TreeVisitor<Tree, ExecutionContext>() {
            @Override
            public Tree visit(Tree tree, ExecutionContext ctx) {
                if (tree instanceof Xml.Document) {
                    return new XmlIsoVisitor<ExecutionContext>() {
                        @Override
                        public Xml.Tag visitTag(Xml.Tag tag, ExecutionContext ctx) {
                            Xml.Tag t = super.visitTag(tag, ctx);
                            if (t.getName().equals("taglib") && t.getAttributes().stream().anyMatch(a -> a.getValue().contains("java.sun.com"))) {
                                return t.withAttributes(tag.getPrefix(), Arrays.asList(
                                        Xml.Attribute.value("uri", "http://jakarta.apache.org/taglibs/core"),
                                        Xml.Attribute.value("prefix", "c")
                                ));
                            }
                            return t;
                        }
                    }.visit(tree, ctx);
                } else if (tree instanceof J.CompilationUnit) {
                    return new JavaIsoVisitor<ExecutionContext>() {
                        @Override
                        public J visitLiteral(J.Literal literal, ExecutionContext ctx) {
                            if (literal.getValueSource() != null && literal.getValueSource().contains("<%")) {
                                return literal.withValueSource("<!-- Removed scriptlet -->")
                                        .withValue(null)
                                        .withMarkers(Markers.EMPTY);
                            }
                            return literal;
                        }
                    }.visit(tree, ctx);
                }
                return tree;
            }
        };
    }
}