"use client";

import { useRouter } from "next/navigation";
import styles from "./nav.module.css";
import Link from "next/link";
import { BookUser, ListCheck, Folder, ChartLine } from "lucide-react";

export default function AdminNav() {
  const router = useRouter();

  async function handleLogout() {
    await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/auth/logout`, {
      method: "POST",
      credentials: "include",
    });
    router.push("/admin/login");
  }

  return (
    <nav className={styles.nav}>
      <div className={styles.nameplate}>
        <Link href="/admin/dashboard">Home</Link>
      </div>
      <ul className={styles.navLinks}>
        <li>
          <Link href="/admin/dashboard/clients">
            {" "}
            <BookUser /> Clients
          </Link>
        </li>
        <li>
          <Link href="/admin/dashboard/projects">
            {" "}
            <Folder /> Projects
          </Link>
        </li>
        <li>
          <Link href="/admin/dashboard/tasks">
            {" "}
            <ListCheck /> Tasks
          </Link>
        </li>
        <li>
          <Link href="/admin/dashboard/reports">
            {" "}
            <ChartLine /> Reports
          </Link>
        </li>
      </ul>
      <button onClick={handleLogout} className={styles.logoutButton}>
        Log out
      </button>
    </nav>
  );
}
