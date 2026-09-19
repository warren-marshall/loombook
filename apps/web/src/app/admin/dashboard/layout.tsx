import AdminNav from "./components/nav/nav";
import styles from "./layout.module.css";

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className={styles.layout}>
      <AdminNav />
      <main className={styles.content}>{children}</main>
    </div>
  );
}
