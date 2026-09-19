"use client";

import { useRouter } from "next/navigation";
import styles from "./nav.module.css";
import Link from "next/link";

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
        <Link href="/admin/dashboard/brief">LoomBook</Link>
      </div>
      <ul className={styles.navLinks}>
        <ul>Pipeline</ul>
        <li>
          <Link href="/admin/dashboard/client/overview">&bull; Overview</Link>
        </li>
        <li>
          <Link href="/admin/dashboard/client">&bull; Clients</Link>
        </li>
        <li>
          <Link href="/admin/dashboard/lead">&bull; Leads</Link>
        </li>
        <ul>Production</ul>
        <li>
          <Link href="/admin/dashboard/project">&bull; Projects</Link>
        </li>
        <li>
          <Link href="/admin/dashboard/task">&bull; Tasks</Link>
        </li>
        <ul>Calendar</ul>
        <li>
          <Link href="/admin/dashboard/calendar">&bull; Calendar</Link>
        </li>
        <li>
          <Link href="/admin/dashboard/shoot">&bull; Shoots</Link>
        </li>
        <li>
          <Link href="/admin/dashboard/calendar">&bull; Locations</Link>
        </li>
        <ul>Business</ul>
        <li>
          <Link href="/admin/dashboard/analytics">&bull; Analytics</Link>
        </li>
        <li>
          <Link href="/admin/dashboard/report">&bull; Reports</Link>
        </li>
        <li>
          <Link href="/admin/dashboard/document">&bull; Documents</Link>
        </li>
      </ul>
      <button onClick={handleLogout} className={styles.logoutButton}>
        Log out
      </button>
    </nav>
  );
}
